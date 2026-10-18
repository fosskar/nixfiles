{
  flake.modules.nixos.arrStack =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      keyDir = "/run/arr-api-keys";

      arrPattern = "<ApiKey>\\K[^<]+";
      arrConfig = user: configFile: {
        inherit user configFile;
        pattern = arrPattern;
      };

      # the apps generate their own key on first start; we only read it back out.
      # each unit runs as the app user so it can read the app's private config dir
      sources = {
        sonarr = arrConfig config.services.sonarr.user "/var/lib/sonarr/.config/NzbDrone/config.xml";
        radarr = arrConfig config.services.radarr.user "/var/lib/radarr/.config/Radarr/config.xml";
        lidarr = arrConfig config.services.lidarr.user "/var/lib/lidarr/.config/Lidarr/config.xml";
        chaptarr = arrConfig config.services.chaptarr.user "${config.services.chaptarr.dataDir}/config.xml";
        sabnzbd = {
          user = config.services.sabnzbd.user;
          configFile = "/var/lib/sabnzbd/sabnzbd.ini";
          pattern = "^api_key\\s*=\\s*\\K\\S+";
        };
        # prowlarr is a DynamicUser; a unit with the same dynamic user name and
        # StateDirectory shares its uid and reaches the private state dir
        prowlarr = arrConfig "prowlarr" "/var/lib/prowlarr/config.xml" // {
          serviceConfig = {
            DynamicUser = true;
            StateDirectory = "prowlarr";
          };
        };
      };

      extractScript =
        serviceName: source:
        pkgs.writeShellScript "${serviceName}-api-key" ''
          set -eu
          umask 027
          export PATH=${
            lib.makeBinPath [
              pkgs.coreutils
              pkgs.gnugrep
            ]
          }

          key=""
          for _ in $(seq 60); do
            key=$(grep -oP '${source.pattern}' ${source.configFile} 2>/dev/null || true)
            [ -n "$key" ] && break
            sleep 1
          done

          if [ -z "$key" ]; then
            echo "no api key in ${source.configFile}" >&2
            exit 1
          fi

          printf '%s' "$key" > ${keyDir}/${serviceName}/api-key.new
          mv ${keyDir}/${serviceName}/api-key.new ${keyDir}/${serviceName}/api-key
        '';

      mkUnit = serviceName: source: {
        description = "extract ${serviceName} api key";
        after = [ "${serviceName}.service" ];
        requires = [ "${serviceName}.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = source.user;
          SupplementaryGroups = [ "${serviceName}-api" ];
          CapabilityBoundingSet = "";
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ReadWritePaths = [ "${keyDir}/${serviceName}" ];
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          PrivateNetwork = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          ProtectClock = true;
          ProtectHostname = true;
          ProtectProc = "invisible";
          RestrictAddressFamilies = "none";
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
            "~@resources"
          ];
          ExecStart = extractScript serviceName source;
        }
        // source.serviceConfig or { };
      };
    in
    {
      config = {
        users.groups = lib.genAttrs (map (serviceName: "${serviceName}-api") (lib.attrNames sources)) (
          _: { }
        );

        # one setgid dir per app, writable only through the <app>-api group. the
        # long-running app is not in that group: root reads these paths through
        # LoadCredential, which follows a symlink the app could otherwise plant
        systemd.tmpfiles.rules = [
          "d ${keyDir} 0755 root root -"
        ]
        ++ map (serviceName: "d ${keyDir}/${serviceName} 2770 root ${serviceName}-api -") (
          lib.attrNames sources
        );

        systemd.services = lib.mapAttrs' (
          serviceName: source: lib.nameValuePair "${serviceName}-api" (mkUnit serviceName source)
        ) sources;
      };
    };
}
