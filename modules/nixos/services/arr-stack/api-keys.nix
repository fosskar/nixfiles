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
        sabnzbd = {
          user = config.services.sabnzbd.user;
          configFile = "/var/lib/sabnzbd/sabnzbd.ini";
          pattern = "^api_key\\s*=\\s*\\K\\S+";
        };
      };

      # prowlarr runs under DynamicUser, so only its own unit can reach the
      # state dir; the key is extracted from inside prowlarr.service instead
      prowlarrConfig = {
        configFile = "/var/lib/prowlarr/config.xml";
        pattern = arrPattern;
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
        };
      };
    in
    {
      config = {
        users.groups = lib.genAttrs (map (serviceName: "${serviceName}-api") (
          lib.attrNames sources ++ [ "prowlarr" ]
        )) (_: { });

        # one setgid dir per app: the app user writes, the <app>-api group
        # reads, and a key is only reachable through the group named on its dir
        systemd.tmpfiles.rules = [
          "d ${keyDir} 0755 root root -"
          "d ${keyDir}/prowlarr 2770 root prowlarr-api -"
        ]
        ++ lib.mapAttrsToList (
          serviceName: source: "d ${keyDir}/${serviceName} 2750 ${source.user} ${serviceName}-api -"
        ) sources;

        systemd.services =
          lib.mapAttrs' (
            serviceName: source: lib.nameValuePair "${serviceName}-api" (mkUnit serviceName source)
          ) sources
          // {
            prowlarr.serviceConfig = {
              SupplementaryGroups = [ "prowlarr-api" ];
              ReadWritePaths = [ "${keyDir}/prowlarr" ];
              ExecStartPost = extractScript "prowlarr" prowlarrConfig;
            };
          };
      };
    };
}
