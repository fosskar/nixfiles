{
  flake.modules.nixos.gatus =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "gatus";
      localHost = "${serviceName}.${config.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8700;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      services.gatus = {
        enable = true;
        environmentFile = config.clan.core.vars.generators.ntfy.files."token-env".path;
        settings = {
          web.port = listenPort;
          storage = {
            type = "sqlite";
            path = "/var/lib/gatus/gatus.db";
          };
          alerting.ntfy = {
            topic = "gatus";
            url = "http://127.0.0.1:8091";
            token = "$NTFY_TOKEN";
            priority = 4;
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

      services.homepage-dashboard.serviceGroups."Monitoring" =
        lib.mkIf config.services.homepage-dashboard.enable
          [
            {
              "Gatus" = {
                href = "https://${localHost}";
                icon = "gatus.svg";
                siteMonitor = listenUrl;
              };
            }
          ];
    };
}
