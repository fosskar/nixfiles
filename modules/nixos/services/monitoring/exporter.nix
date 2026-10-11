{
  flake.modules.nixos.exporter =
    { config, lib, ... }:
    {
      services.prometheus.exporters = {
        nginx = {
          port = 9113;
          openFirewall = false;
          scrapeUri = "http://127.0.0.1:80/nginx_status";
        };

        postgres = {
          port = 9187;
          openFirewall = false;
          runAsLocalSuperUser = true;
        };

        restic = {
          port = 9753;
          openFirewall = false;
          refreshInterval = 3600;
        };

        nut = {
          port = 9199;
          listenAddress = "127.0.0.1";
          openFirewall = false;
          nutServer = "127.0.0.1";
        };

        zfs = {
          port = 9134;
          listenAddress = "127.0.0.1";
          openFirewall = false;
        };
      };

      # --- grafana ---

      services.grafana.provision = lib.mkIf config.services.prometheus.exporters.zfs.enable {
        dashboards.settings.providers = [
          {
            name = "zfs";
            folder = "Storage";
            options.path = ./zfs.dashboard.json;
          }
        ];
        alerting.rules.settings.groups = lib.importJSON ./zfs.alerts.json;
      };
    };
}
