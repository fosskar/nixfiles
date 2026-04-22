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
      serviceDomain = "seerr.${acmeDomain}";
      bindAddress = "127.0.0.1";
      port = 5055;
      internalUrl = "http://${bindAddress}:${toString port}";
    in
    {
      config = lib.mkIf cfg.seerr.enable {
        # --- service ---

        services.seerr = {
          enable = true;
          inherit port;
          openFirewall = false;
        };

        systemd.services.seerr.serviceConfig.UMask = "0027";

        # --- homepage ---

        nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
          {
            name = "Seerr";
            category = "Media";
            icon = "jellyseerr.svg";
            href = "https://${serviceDomain}";
            siteMonitor = internalUrl;
          }
        ];

        # --- gatus ---

        nixfiles.gatus.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Seerr";
            url = internalUrl;
            group = "Media";
          }
        ];

        # --- caddy ---

        # no proxy-auth - seerr has built-in auth
        nixfiles.caddy.vhosts.seerr = {
          inherit port;
        };

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
            sqlite3 /var/lib/seerr/db/db.sqlite3 ".backup '/var/backup/seerr/db.sqlite3'"
          '';
        };
      };
    };
}
