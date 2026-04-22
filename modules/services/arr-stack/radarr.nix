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
      serviceDomain = "radarr.${acmeDomain}";
      bindAddress = "127.0.0.1";
      port = 7878;
      internalUrl = "http://${bindAddress}:${toString port}";
    in
    {
      config = lib.mkIf cfg.radarr.enable {
        # --- service ---

        services.radarr = {
          enable = true;
          openFirewall = false;
          group = "media";
          settings.server.port = port;
        };

        # --- homepage ---

        nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
          {
            name = "Radarr";
            category = "Arr Stack";
            icon = "radarr.svg";
            href = "https://${serviceDomain}";
            siteMonitor = internalUrl;
          }
        ];

        # --- gatus ---

        nixfiles.gatus.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Radarr";
            url = internalUrl;
            group = "Arr Stack";
          }
        ];

        # --- caddy ---

        nixfiles.caddy.vhosts.radarr = {
          inherit port;
          proxy-auth = cfg.authelia.enable;
        };

        # --- backup ---

        clan.core.state.radarr = {
          folders = [ "/var/backup/radarr" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.sqlite
                pkgs.coreutils
              ]
            }
            mkdir -p /var/backup/radarr
            sqlite3 /var/lib/radarr/.config/Radarr/radarr.db ".backup '/var/backup/radarr/radarr.db'"
          '';
        };
      };
    };
}
