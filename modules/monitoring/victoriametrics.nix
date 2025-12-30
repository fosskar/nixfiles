{
  config,
  lib,
  ...
}:
let
  cfg = config.nixfiles.monitoring.victoriametrics;
in
{
  options.nixfiles.monitoring.victoriametrics = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "victoriametrics time series database";
    };

    retentionPeriod = lib.mkOption {
      type = lib.types.str;
      default = "3";
      description = "data retention in months";
    };

    scrapeConfigs = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "prometheus scrape configs";
    };
  };

  config = lib.mkIf cfg.enable {
    # nginx reverse proxy
    nixfiles.nginx.vhosts.vm.port = 8428;

    services.victoriametrics = {
      enable = true;
      listenAddress = "127.0.0.1:8428";
      inherit (cfg) retentionPeriod;

      extraOptions = [
        "-promscrape.dropOriginalLabels=false"
        "-selfScrapeInterval=10s"
      ];

      prometheusConfig.scrape_configs = cfg.scrapeConfigs;
    };

    # grafana datasource
    services.grafana.provision.datasources.settings.datasources = [
      {
        name = "VictoriaMetrics";
        type = "prometheus";
        access = "proxy";
        url = "http://${config.services.victoriametrics.listenAddress}";
        isDefault = true;
      }
    ];
  };
}
