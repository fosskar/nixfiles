{
  flake.modules.nixos.victoriaMetrics =
    {
      config,
      domains,
      lib,
      ...
    }:
    let
      serviceName = "vm";
      localHost = "${serviceName}.${domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8428;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      config = lib.mkIf config.services.victoriametrics.enable {
        services.victoriametrics = {
          listenAddress = lib.mkDefault "${listenAddress}:${toString listenPort}";
          retentionPeriod = lib.mkDefault "3";

          extraOptions = [
            "-promscrape.dropOriginalLabels=false"
            "-selfScrapeInterval=10s"
            "-enableTCP6"
          ];

          prometheusConfig.scrape_configs = lib.mkBefore (
            [
              {
                job_name = "victoriametrics";
                static_configs = [ { targets = [ config.services.victoriametrics.listenAddress ]; } ];
              }
            ]
            ++ lib.optionals config.services.telegraf.enable [
              {
                job_name = "telegraf";
                static_configs = [
                  {
                    targets = [ "127.0.0.1:9273" ];
                    labels.type = "telegraf";
                  }
                ];
              }
            ]
            ++ lib.optionals config.services.prometheus.exporters.zfs.enable [
              {
                job_name = "zfs-exporter";
                static_configs = [
                  { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.zfs.port}" ]; }
                ];
              }
            ]
            ++ lib.optionals config.services.prometheus.exporters.node.enable [
              {
                job_name = "node-exporter";
                static_configs = [
                  { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ]; }
                ];
              }
            ]
          );
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

        # --- homepage ---

        services.homepage-dashboard.serviceGroups."Monitoring" =
          lib.mkIf config.services.homepage-dashboard.enable
            [
              {
                "VictoriaMetrics" = {
                  href = "https://${localHost}";
                  icon = "victoriametrics.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];

        # --- gatus ---

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "VictoriaMetrics";
            url = listenUrl;
            group = "Monitoring";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "ntfy"; } ];
          }
        ];

        # --- caddy ---

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          import authelia
          reverse_proxy ${listenUrl}
        '';
      };
    };
}
