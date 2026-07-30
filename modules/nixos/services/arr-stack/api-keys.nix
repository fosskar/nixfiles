{
  flake.modules.nixos.arrStack =
    { lib, pkgs, ... }:
    let
      keyDir = "/run/arr-api-keys";

      arrConfig = configFile: {
        inherit configFile;
        pattern = "<ApiKey>\\K[^<]+";
      };

      # the apps generate their own key on first start; we only read it back out
      sources = {
        sonarr = arrConfig "/var/lib/sonarr/.config/NzbDrone/config.xml";
        radarr = arrConfig "/var/lib/radarr/.config/Radarr/config.xml";
        lidarr = arrConfig "/var/lib/lidarr/.config/Lidarr/config.xml";
        # prowlarr runs under DynamicUser
        prowlarr = arrConfig "/var/lib/private/prowlarr/config.xml";
        sabnzbd = {
          configFile = "/var/lib/sabnzbd/sabnzbd.ini";
          pattern = "^api_key\\s*=\\s*\\K\\S+";
        };
      };

      mkUnit = serviceName: source: {
        description = "extract ${serviceName} api key";
        after = [ "${serviceName}.service" ];
        requires = [ "${serviceName}.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          UMask = "0027";
          ExecStart = pkgs.writeShellScript "${serviceName}-api-key" ''
            set -eu
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

            printf '%s' "$key" > ${keyDir}/${serviceName}.api-key.new
            chgrp ${serviceName}-api ${keyDir}/${serviceName}.api-key.new
            mv ${keyDir}/${serviceName}.api-key.new ${keyDir}/${serviceName}.api-key
          '';
        };
      };
    in
    {
      config = {
        users.groups = lib.mapAttrs' (serviceName: _: lib.nameValuePair "${serviceName}-api" { }) sources;

        # 0751: group members traverse but cannot list, so a key is only
        # reachable by the group named on the file itself
        systemd.tmpfiles.rules = [ "d ${keyDir} 0751 root root -" ];

        systemd.services = lib.mapAttrs' (
          serviceName: source: lib.nameValuePair "${serviceName}-api" (mkUnit serviceName source)
        ) sources;
      };
    };
}
