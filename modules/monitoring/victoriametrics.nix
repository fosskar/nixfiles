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

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1:8428";
      description = "listen address for VictoriaMetrics";
    };
  };

  config = lib.mkIf cfg.enable {
    # nginx reverse proxy
    nixfiles.nginx.vhosts.vm.port = 8428;

    services.victoriametrics = {
      enable = true;
      inherit (cfg) listenAddress;
      inherit (cfg) retentionPeriod;

      extraOptions = [
        "-promscrape.dropOriginalLabels=false"
        "-selfScrapeInterval=10s"
      ];

      prometheusConfig.scrape_configs =
        let
          telegrafCfg = config.nixfiles.monitoring.telegraf;
          exporterCfg = config.nixfiles.monitoring.exporter;
        in
        # self-scrape
        [
          {
            job_name = "victoriametrics";
            static_configs = [ { targets = [ config.services.victoriametrics.listenAddress ]; } ];
          }
        ]
        # telegraf
        ++ lib.optionals telegrafCfg.enable [
          {
            job_name = "telegraf";
            static_configs = [
              {
                targets = [ "127.0.0.1:${toString telegrafCfg.listenPort}" ];
                labels.type = "telegraf";
              }
            ];
          }
        ]
        # zfs exporter
        ++ lib.optionals exporterCfg.enableZfsExporter [
          {
            job_name = "zfs-exporter";
            static_configs = [
              { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.zfs.port}" ]; }
            ];
          }
        ]
        # node exporter
        ++ lib.optionals exporterCfg.enableNodeExporter [
          {
            job_name = "node-exporter";
            static_configs = [
              { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ]; }
            ];
          }
        ]
        # extra configs
        ++ cfg.scrapeConfigs;
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
