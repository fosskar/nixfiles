# protomaps basemap for the grid app: monthly europe extract uploaded into the
# garage `maps` bucket, served anonymously by the garage web endpoint (:3902)
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
      workDir = "/tank/scratch/protomaps";
      keys = config.clan.core.vars.generators.garage-buckets;
      region = config.services.garage.settings.s3_api.s3_region;
    in
    {
      systemd.services.protomaps-refresh = {
        description = "protomaps europe extract -> garage ${bucket} bucket";
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
          LoadCredential = [
            "access_key:${keys.files."${bucket}_access_key_id".path}"
            "secret_key:${keys.files."${bucket}_secret_access_key".path}"
          ];
        };
        script = ''
          set -euo pipefail
          mkdir -p ${workDir}
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

          pmtiles extract "https://build.protomaps.com/$build" europe.pmtiles \
            --bbox=-25,34,45,72 --download-threads=8

          export AWS_ACCESS_KEY_ID="$(cat "$CREDENTIALS_DIRECTORY"/access_key)"
          export AWS_SECRET_ACCESS_KEY="$(cat "$CREDENTIALS_DIRECTORY"/secret_key)"
          pmtiles upload europe.pmtiles ${object} \
            --bucket='s3://${bucket}?endpoint=http://127.0.0.1:3900&region=${region}&use_path_style=true'

          rm -f europe.pmtiles
        '';
      };

      systemd.timers.protomaps-refresh = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "monthly";
          Persistent = true;
          RandomizedDelaySec = "6h";
        };
      };

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
