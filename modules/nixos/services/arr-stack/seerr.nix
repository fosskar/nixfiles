{
  flake.modules.nixos.arrStack =
    {
      config,
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "seerr";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 5055;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      config = {
        # --- service ---

        services.seerr = {
          enable = true;
          port = listenPort;
          openFirewall = false;
        };

        systemd.services.seerr = {
          environment.HOST = listenAddress;
          serviceConfig = {
            UMask = "0027";
            EnvironmentFile = config.clan.core.vars.generators.seerr-api.files.env.path;
          };
        };

        # seerr takes API_KEY over its stored key, so other services can be
        # given the key without reading it back out of seerr
        clan.core.vars.generators.seerr-api = {
          files = {
            api-key.restartUnits = [ "jellyfin.service" ];
            env.restartUnits = [ "seerr.service" ];
          };
          runtimeInputs = [ pkgs.pwgen ];
          script = ''
            key=$(pwgen -s 64 1)
            printf '%s' "$key" > "$out/api-key"
            printf 'API_KEY=%s\n' "$key" > "$out/env"
          '';
        };

        # --- homepage ---

        services.homepage-dashboard.services = [
          {
            "media" = [
              {
                "Seerr" = {
                  href = "https://${localHost}";
                  icon = "jellyseerr.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];
          }
        ];

        # --- gatus ---

        services.gatus.settings.endpoints = [
          {
            name = "Seerr";
            url = "https://${localHost}";
            enabled = true;
            alerts = [ { type = "matrix"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];

        # --- caddy ---

        # no proxy-auth - seerr has built-in auth
        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy ${listenUrl}
        '';

        # --- backup ---

        clan.core.state.seerr = {
          folders = [ "/var/backup/seerr" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.sqlite
                pkgs.coreutils
              ]
            }
            mkdir -p /var/backup/seerr
            sqlite3 -nofollow /var/lib/private/seerr/db/db.sqlite3 ".backup '/var/backup/seerr/db.sqlite3'"
          '';
        };
      };
    };
}
