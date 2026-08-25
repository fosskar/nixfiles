{
  flake.modules.nixos.victoriaLogs =
    {
      config,
      lib,
      ...
    }:
    let
      listenPort = lib.last (lib.splitString ":" config.services.victorialogs.listenAddress);
    in
    {
      config = lib.mkIf config.services.victorialogs.enable {
        services.victorialogs = {
          listenAddress = lib.mkDefault "0.0.0.0:9428";
          extraOptions = [ "-enableTCP6" ];
        };

        services.victoriametrics.prometheusConfig.scrape_configs =
          lib.mkIf config.services.victoriametrics.enable
            [
              {
                job_name = "victorialogs";
                static_configs = [
                  {
                    targets = [ "127.0.0.1:${listenPort}" ];
                    labels = {
                      machine = config.networking.hostName;
                      source = "local";
                      type = "victorialogs";
                    };
                  }
                ];
                metric_relabel_configs = [
                  {
                    source_labels = [ "__name__" ];
                    regex = "flag";
                    action = "drop";
                  }
                ];
              }
            ];

        # grafana datasource
        services.grafana.provision.datasources.settings.datasources = [
          {
            name = "VictoriaLogs";
            type = "victoriametrics-logs-datasource";
            access = "proxy";
            url = "http://127.0.0.1:${listenPort}";
          }
        ];
      };
    };
}
