{
  flake.modules.nixos.arrStack =
    {
      nflib,
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "navidrome";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 4533;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      config = {
        # --- service ---

        # navidrome has its own auth/login, so no authelia external-auth
        # integration here (unlike the *arr services).
        services.navidrome = {
          enable = true;
          openFirewall = false;
          group = "media";
          settings = {
            Address = listenAddress;
            Port = listenPort;
            MusicFolder = "/tank/media/music";
          };
        };

        # --- homepage ---

        services.homepage-dashboard.serviceGroups."media" = [
          {
            "Navidrome" = {
              href = "https://${localHost}";
              icon = "navidrome.svg";
              siteMonitor = listenUrl;
            };
          }
        ];

        # --- gatus ---

        services.gatus.settings.endpoints = [
          (nflib.gatusEndpoint {
            name = "Navidrome";
            url = listenUrl;
            group = "Media";
          })
        ];

        # --- caddy ---

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy ${listenUrl}
        '';

        # --- backup ---

        clan.core.state.navidrome = {
          folders = [ "/var/backup/navidrome" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.sqlite
                pkgs.coreutils
              ]
            }
            mkdir -p /var/backup/navidrome
            sqlite3 /var/lib/navidrome/navidrome.db ".backup '/var/backup/navidrome/navidrome.db'"
          '';
        };
      };
    };
}
