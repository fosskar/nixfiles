{
  flake.modules.nixos.gatus =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      port = 8700;
      bindAddress = "127.0.0.1";
      internalUrl = "http://${bindAddress}:${toString port}";
    in
    {
      services.gatus = {
        enable = true;
        environmentFile = config.clan.core.vars.generators.ntfy.files."token-env".path;
        settings = {
          web.port = port;
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

      services.caddy.virtualHosts."gatus.nx3.eu".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString port}
      '';

      services.homepage-dashboard.services = lib.mkIf config.services.homepage-dashboard.enable [
        {
          "Monitoring" = [
            {
              "Gatus" = {
                href = "https://gatus.nx3.eu";
                icon = "gatus.svg";
                siteMonitor = internalUrl;
              };
            }
          ];
        }
      ];
    };
}
