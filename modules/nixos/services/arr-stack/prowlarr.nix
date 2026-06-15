{
  flake.modules.nixos.arrStack =
    {
      nflib,
      flake-self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "prowlarr";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 9696;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      config = {
        # --- service ---

        services.prowlarr = {
          enable = true;
          openFirewall = false;
          settings = {
            auth = lib.mkIf (config.services.authelia.instances.main.enable or false) {
              method = "External";
              required = "Enabled";
            };
            server = {
              bindaddress = listenAddress;
              port = listenPort;
            };
          };
        };

        # --- homepage ---

        services.homepage-dashboard.serviceGroups."arr-stack" =
          lib.mkIf config.services.homepage-dashboard.enable
            [
              {
                "Prowlarr" = {
                  href = "https://${localHost}";
                  icon = "prowlarr.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];

        # --- gatus ---

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          (nflib.gatusEndpoint {
            name = "Prowlarr";
            url = listenUrl;
            group = "Arr Stack";
          })
        ];

        # --- caddy ---

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          ${lib.optionalString (config.services.authelia.instances.main.enable or false) "import authelia"}
          reverse_proxy ${listenUrl}
        '';

        # --- backup ---

        clan.core.state.prowlarr = {
          folders = [ "/var/backup/prowlarr" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.sqlite
                pkgs.coreutils
              ]
            }
            mkdir -p /var/backup/prowlarr
            sqlite3 /var/lib/private/prowlarr/prowlarr.db ".backup '/var/backup/prowlarr/prowlarr.db'"
          '';
        };
      };
    };
}
