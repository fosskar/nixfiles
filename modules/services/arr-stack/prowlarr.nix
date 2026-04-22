{
  flake.modules.nixos.arrStack =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.nixfiles.arrStack;
      acmeDomain = config.nixfiles.caddy.domain;
      serviceDomain = "prowlarr.${acmeDomain}";
      bindAddress = "127.0.0.1";
      port = 9696;
      internalUrl = "http://${bindAddress}:${toString port}";
    in
    {
      config = lib.mkIf cfg.prowlarr.enable {
        # --- service ---

        services.prowlarr = {
          enable = true;
          openFirewall = false;
          settings.server.port = port;
        };

        # --- homepage ---

        nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
          {
            name = "Prowlarr";
            category = "Arr Stack";
            icon = "prowlarr.svg";
            href = "https://${serviceDomain}";
            siteMonitor = internalUrl;
          }
        ];

        # --- gatus ---

        nixfiles.gatus.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Prowlarr";
            url = internalUrl;
            group = "Arr Stack";
          }
        ];

        # --- caddy ---

        nixfiles.caddy.vhosts.prowlarr = {
          inherit port;
          proxy-auth = cfg.authelia.enable;
        };

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
