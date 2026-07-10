{
  flake.modules.nixos.arrStack =
    {
      flake-self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "bazarr";
      localHost = "${serviceName}.${flake-self.domains.local}";
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

        systemd.services.bazarr.serviceConfig.UMask = "0002";

        # --- homepage ---

        services.homepage-dashboard.services = [
          {
            "arr-stack" = [
              {
                "Bazarr" = {
                  href = "https://${localHost}";
                  icon = "bazarr.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];
          }
        ];

        # --- gatus ---

        services.gatus.settings.endpoints = [
          {
            name = "Bazarr";
            # backend check on purpose: the edge is forward-auth, authelia answers 302 without reaching the service
            url = listenUrl;
            enabled = true;
            alerts = [ { type = "email"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
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
