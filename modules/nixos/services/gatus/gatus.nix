{
  flake.modules.nixos.gatus =
    {
      flake-self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "gatus";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8700;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      services.gatus = {
        enable = true;
        settings = {
          web.port = listenPort;
          storage = {
            type = "sqlite";
            path = "/var/lib/gatus/gatus.db";
          };
          alerting.email = {
            from = "$SMTP_FROM";
            username = "$SMTP_USER";
            password = "$SMTP_PASSWORD";
            host = "$SMTP_HOST";
            port = "$SMTP_PORT";
            to = "gatus@nx3.eu";
            default-alert = {
              enabled = true;
              failure-threshold = 2;
              success-threshold = 2;
              send-on-resolved = true;
            };
          };
        };
      };

      clan.core.state.gatus = {
        folders = [ "/var/backup/gatus" ];
        preBackupScript = ''
          export PATH=${
            lib.makeBinPath [
              pkgs.sqlite
              pkgs.coreutils
            ]
          }
          mkdir -p /var/backup/gatus
          sqlite3 /var/lib/gatus/gatus.db ".backup '/var/backup/gatus/gatus.db'"
        '';
      };

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';

      systemd.services.gatus.serviceConfig.EnvironmentFile =
        config.clan.core.vars.generators.smtp.files."smtp-env".path;

      services.homepage-dashboard.serviceGroups."monitoring" =
        lib.mkIf config.services.homepage-dashboard.enable
          [
            {
              "Gatus" = {
                href = "https://${localHost}";
                icon = "gatus.svg";
                siteMonitor = listenUrl;
                widget = {
                  type = "gatus";
                  url = listenUrl;
                };
              };
            }
          ];
    };
}
