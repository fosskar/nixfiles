{
  flake.modules.nixos.arrStack =
    {
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "audiobookshelf";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 13378;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      config = {
        # --- service ---

        services.audiobookshelf = {
          enable = true;
          host = listenAddress;
          port = listenPort;
          openFirewall = false;
          group = "media";
        };

        # --- homepage ---

        services.homepage-dashboard.services = [
          {
            "media" = [
              {
                "Audiobookshelf" = {
                  href = "https://${localHost}";
                  icon = "sh-audiobookshelf";
                  siteMonitor = listenUrl;
                };
              }
            ];
          }
        ];

        # --- gatus ---

        services.gatus.settings.endpoints = [
          {
            name = "Audiobookshelf";
            url = "https://${localHost}/healthcheck";
            enabled = true;
            alerts = [ { type = "matrix"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];

        # --- caddy ---

        # no proxy-auth - audiobookshelf has built-in auth
        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy ${listenUrl}
        '';

        # --- backup ---

        clan.core.state.audiobookshelf = {
          folders = [ "/var/backup/audiobookshelf" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.sqlite
                pkgs.coreutils
              ]
            }
            mkdir -p /var/backup/audiobookshelf
            sqlite3 /var/lib/audiobookshelf/config/absdatabase.sqlite ".backup '/var/backup/audiobookshelf/absdatabase.sqlite'"
          '';
        };
      };
    };
}
