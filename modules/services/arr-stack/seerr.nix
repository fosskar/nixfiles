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
      serviceDomain = "seerr.${acmeDomain}";
      bindAddress = "127.0.0.1";
      port = 5055;
      internalUrl = "http://${bindAddress}:${toString port}";
    in
    {
      config = {
        # --- service ---

        services.seerr = {
          enable = true;
          inherit port;
          openFirewall = false;
        };

        systemd.services.seerr.serviceConfig.UMask = "0027";

        # --- homepage ---

        services.homepage-dashboard.services = lib.mkIf config.services.homepage-dashboard.enable [
          {
            "Media" = [
              {
                "Seerr" = {
                  href = "https://${serviceDomain}";
                  icon = "jellyseerr.svg";
                  siteMonitor = internalUrl;
                };
              }
            ];
          }
        ];

        # --- gatus ---

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Seerr";
            url = internalUrl;
            group = "Media";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "ntfy"; } ];
          }
        ];

        # --- caddy ---

        # no proxy-auth - seerr has built-in auth
        services.caddy.virtualHosts."seerr.nx3.eu".extraConfig = ''
          reverse_proxy 127.0.0.1:${toString port}
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
            sqlite3 /var/lib/seerr/db/db.sqlite3 ".backup '/var/backup/seerr/db.sqlite3'"
          '';
        };
      };
    };
}
