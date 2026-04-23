{
  flake.modules.nixos.arrStack =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      acmeDomain = "nx3.eu";
      serviceDomain = "prowlarr.${acmeDomain}";
      bindAddress = "127.0.0.1";
      port = 9696;
      internalUrl = "http://${bindAddress}:${toString port}";
    in
    {
      config = {
        # --- service ---

        services.prowlarr = {
          enable = true;
          openFirewall = false;
          settings.server.port = port;
        };

        # --- homepage ---

        services.homepage-dashboard.services = lib.mkIf config.services.homepage-dashboard.enable [
          {
            "Arr Stack" = [
              {
                "Prowlarr" = {
                  href = "https://${serviceDomain}";
                  icon = "prowlarr.svg";
                  siteMonitor = internalUrl;
                };
              }
            ];
          }
        ];

        # --- gatus ---

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Prowlarr";
            url = internalUrl;
            group = "Arr Stack";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "ntfy"; } ];
          }
        ];

        # --- caddy ---

        services.caddy.virtualHosts."prowlarr.nx3.eu".extraConfig = ''
          ${lib.optionalString (config.services.authelia.instances.main.enable or false) "import authelia"}
          reverse_proxy 127.0.0.1:${toString port}
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
