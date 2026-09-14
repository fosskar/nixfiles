# protomaps basemap for the grid app and the opencloud maps app: quarterly
# planet build uploaded into the garage `maps` bucket, served anonymously by
# the garage web endpoint (:3902)
# and exposed publicly as maps.<public> via netbird-proxy (mapping lives in the
# netbird ui, not here).
{
  flake.modules.nixos.protomaps =
    {
      config,
      flake-self,
      pkgs,
      ...
    }:
    let
      bucket = "maps";
      object = "protomaps.pmtiles";
      publicHost = "maps.${flake-self.domains.public}";
      localHost = "maps.${flake-self.domains.local}";
      workDir = "/tank/scratch/protomaps";
      keys = config.clan.core.vars.generators.garage-buckets;
      # glyphs for the protomaps basemap style, served next to the tiles so
      # the opencloud maps app needs nothing from protomaps.github.io
      basemapAssets = pkgs.fetchFromGitHub {
        owner = "protomaps";
        repo = "basemaps-assets";
        rev = "028c18f713baecad011301ff7a69acc39bcc2ae7";
        hash = "sha256-P52xWPZr59voAumONX/n8g15xxqgqyXYIRoZmNSawAw=";
      };
      region = config.services.garage.settings.s3_api.s3_region;
    in
    {
      users.users.protomaps = {
        isSystemUser = true;
        group = "protomaps";
      };
      users.groups.protomaps = { };
      # Z: existing root-owned work dir from before the unit had its own user
      systemd.tmpfiles.rules = [
        "d ${workDir} 0750 protomaps protomaps -"
        "Z ${workDir} - protomaps protomaps -"
      ];

      systemd.services.protomaps-refresh = {
        description = "protomaps planet build -> garage ${bucket} bucket";
        after = [
          "network-online.target"
          "garage.service"
        ];
        wants = [ "network-online.target" ];
        unitConfig.RequiresMountsFor = [ workDir ];
        path = [
          pkgs.pmtiles
          pkgs.coreutils
          pkgs.curl
        ];
        serviceConfig = {
          Type = "oneshot";
          TimeoutStartSec = "12h";
          User = "protomaps";
          Group = "protomaps";
          NoNewPrivileges = true;
          CapabilityBoundingSet = "";
          ProtectSystem = "strict";
          ReadWritePaths = [ workDir ];
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
          ];
          LoadCredential = [
            "access_key:${keys.files."${bucket}_access_key_id".path}"
            "secret_key:${keys.files."${bucket}_secret_access_key".path}"
          ];
        };
        script = ''
          set -euo pipefail
          cd ${workDir}

          # builds.json lives on build-metadata.protomaps.dev, which the lan
          # adguardhome blocks; probe the daily YYYYMMDD.pmtiles names instead.
          build=""
          for d in $(seq 0 7); do
            candidate="$(date -u -d "-$d day" +%Y%m%d).pmtiles"
            if curl -sfIL "https://build.protomaps.com/$candidate" >/dev/null; then
              build=$candidate
              break
            fi
          done
          [ -n "$build" ]

          # one stream: 8 parallel downloads saturated the wan link and
          # drowned the router (dns/control plane starved) on 2026-07-18.
          # ~140GB, resumable
          curl -fSL --retry 10 --retry-delay 30 --continue-at - \
            -o planet.pmtiles "https://build.protomaps.com/$build"

          AWS_ACCESS_KEY_ID="$(cat "$CREDENTIALS_DIRECTORY"/access_key)"
          AWS_SECRET_ACCESS_KEY="$(cat "$CREDENTIALS_DIRECTORY"/secret_key)"
          export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
          pmtiles upload planet.pmtiles ${object} \
            --bucket='s3://${bucket}?endpoint=http://127.0.0.1:3900&region=${region}&use_path_style=true'

          rm -f planet.pmtiles
          touch ${workDir}/.bootstrapped
        '';
      };

      # browsers on other origins (opencloud maps app) read the pmtiles with
      # range requests; garage applies the bucket cors rules on the web endpoint
      systemd.services.protomaps-cors = {
        description = "cors rules for the garage ${bucket} bucket";
        wantedBy = [ "multi-user.target" ];
        after = [ "garage-buckets-init.service" ];
        requires = [ "garage-buckets-init.service" ];
        path = [
          pkgs.coreutils
          pkgs.curl
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "protomaps";
          Group = "protomaps";
          NoNewPrivileges = true;
          CapabilityBoundingSet = "";
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
          ];
          LoadCredential = [
            "access_key:${keys.files."${bucket}_access_key_id".path}"
            "secret_key:${keys.files."${bucket}_secret_access_key".path}"
          ];
        };
        script = ''
          set -euo pipefail
          curl -sfS --aws-sigv4 "aws:amz:${region}:s3" \
            --user "$(cat "$CREDENTIALS_DIRECTORY"/access_key):$(cat "$CREDENTIALS_DIRECTORY"/secret_key)" \
            -X PUT "http://127.0.0.1:3900/${bucket}/?cors" \
            -H 'Content-Type: application/xml' \
            --data-binary @${pkgs.writeText "protomaps-cors.xml" ''
              <CORSConfiguration>
                <CORSRule>
                  <AllowedOrigin>*</AllowedOrigin>
                  <AllowedMethod>GET</AllowedMethod>
                  <AllowedMethod>HEAD</AllowedMethod>
                  <AllowedHeader>*</AllowedHeader>
                  <ExposeHeader>Content-Range</ExposeHeader>
                  <ExposeHeader>Content-Length</ExposeHeader>
                  <ExposeHeader>ETag</ExposeHeader>
                </CORSRule>
              </CORSConfiguration>
            ''}
        '';
      };

      # ~1000 small objects, put once per pinned revision (marker in workDir)
      systemd.services.protomaps-fonts = {
        description = "protomaps basemap fonts -> garage ${bucket} bucket";
        wantedBy = [ "multi-user.target" ];
        after = [ "garage-buckets-init.service" ];
        requires = [ "garage-buckets-init.service" ];
        unitConfig = {
          RequiresMountsFor = [ workDir ];
          ConditionPathExists = "!${workDir}/.fonts-${baseNameOf basemapAssets}";
        };
        path = [
          pkgs.coreutils
          pkgs.curl
          pkgs.findutils
          pkgs.gnused
        ];
        serviceConfig = {
          Type = "oneshot";
          User = "protomaps";
          Group = "protomaps";
          NoNewPrivileges = true;
          CapabilityBoundingSet = "";
          ProtectSystem = "strict";
          ReadWritePaths = [ workDir ];
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
          ];
          LoadCredential = [
            "access_key:${keys.files."${bucket}_access_key_id".path}"
            "secret_key:${keys.files."${bucket}_secret_access_key".path}"
          ];
        };
        script = ''
          set -euo pipefail
          auth="$(cat "$CREDENTIALS_DIRECTORY"/access_key):$(cat "$CREDENTIALS_DIRECTORY"/secret_key)"
          cd ${basemapAssets}/fonts
          find . -name '*.pbf' -printf '%P\n' | while read -r f; do
            curl -sfS --aws-sigv4 "aws:amz:${region}:s3" --user "$auth" \
              -X PUT "http://127.0.0.1:3900/${bucket}/fonts/$(printf %s "$f" | sed 's/ /%20/g')" \
              -H 'Content-Type: application/x-protobuf' \
              --data-binary "@$f"
          done
          touch ${workDir}/.fonts-${baseNameOf basemapAssets}
        '';
      };

      # first refresh on deploy (garage-layout-init pattern); the quarterly timer
      # owns every later run, so the marker only gates this kick.
      systemd.services.protomaps-bootstrap = {
        description = "first protomaps refresh after deploy";
        wantedBy = [ "multi-user.target" ];
        after = [ "garage-buckets-init.service" ];
        unitConfig.ConditionPathExists = "!${workDir}/.bootstrapped";
        serviceConfig.Type = "oneshot";
        script = "systemctl start --no-block protomaps-refresh.service";
      };

      systemd.timers.protomaps-refresh = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-01,04,07,10-01 03:00";
          Persistent = true;
          RandomizedDelaySec = "2h";
        };
      };

      # lan and mesh clients read the bucket without the gateway hop; garage
      # routes the web endpoint by host, hence the bucket alias in the inventory
      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy 127.0.0.1:3902
      '';

      services.gatus.settings.endpoints = [
        {
          name = "Maps";
          # HEAD: the object is ~30GB; a body check would download it.
          url = "https://${publicHost}/${object}";
          method = "HEAD";
          group = "public";
          enabled = true;
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [ { type = "email"; } ];
        }
      ];
    };
}
