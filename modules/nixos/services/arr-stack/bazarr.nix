{
  flake.modules.nixos.arrStack =
    {
      config,
      domains,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "bazarr";
      localHost = "${serviceName}.${domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 6767;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      config = {
        # --- service ---

        services.bazarr = {
          enable = true;
          openFirewall = false;
          group = "media";
          inherit listenPort;
        };

        systemd.services.bazarr.serviceConfig.UMask = "0027";

        # --- homepage ---

        services.homepage-dashboard.serviceGroups."Arr Stack" =
          lib.mkIf config.services.homepage-dashboard.enable
            [
              {
                "Bazarr" = {
                  href = "https://${localHost}";
                  icon = "bazarr.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];

        # --- gatus ---

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Bazarr";
            url = listenUrl;
            group = "Arr Stack";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "ntfy"; } ];
          }
        ];

        # --- caddy ---

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          ${lib.optionalString (config.services.authelia.instances.main.enable or false) "import authelia"}
          reverse_proxy ${listenUrl}
        '';

        # --- backup ---

        clan.core.state.bazarr = {
          folders = [ "/var/backup/bazarr" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.sqlite
                pkgs.coreutils
              ]
            }
            mkdir -p /var/backup/bazarr
            sqlite3 /var/lib/bazarr/db/bazarr.db ".backup '/var/backup/bazarr/bazarr.db'"
          '';
        };
      };
    };
}
