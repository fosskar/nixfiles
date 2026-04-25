{
  flake.modules.nixos.arrStack =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "seerr";
      localHost = "${serviceName}.${config.domains.local}";
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

        systemd.services.seerr.serviceConfig.UMask = "0027";

        # --- homepage ---

        services.homepage-dashboard.serviceGroups."Media" =
          lib.mkIf config.services.homepage-dashboard.enable
            [
              {
                "Seerr" = {
                  href = "https://${localHost}";
                  icon = "jellyseerr.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];

        # --- gatus ---

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Seerr";
            url = listenUrl;
            group = "Media";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "ntfy"; } ];
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
            sqlite3 /var/lib/seerr/db/db.sqlite3 ".backup '/var/backup/seerr/db.sqlite3'"
          '';
        };
      };
    };
}
