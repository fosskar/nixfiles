{
  flake.modules.nixos.victoriaMetrics =
    {
      flake-self,
      config,
      lib,
      ...
    }:
    let
      serviceName = "vm";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8428;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
      autheliaEnabled = config.services.authelia.instances.main.enable or false;
    in
    {
      config = lib.mkIf config.services.victoriametrics.enable {
        services.victoriametrics = {
          listenAddress = lib.mkDefault "${listenAddress}:${toString listenPort}";
          retentionPeriod = lib.mkDefault "3";

          extraOptions = [
            "-promscrape.dropOriginalLabels=false"
            "-enableTCP6"
          ];

          prometheusConfig.scrape_configs = lib.mkBefore (
            [
              {
                job_name = "victoriametrics";
                scrape_interval = "30s";
                static_configs = [
                  {
                    targets = [ config.services.victoriametrics.listenAddress ];
                    labels = {
                      machine = config.networking.hostName;
                      source = "local";
                      type = "victoriametrics";
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
            ]
            ++ lib.optionals config.services.prometheus.exporters.zfs.enable [
              {
                job_name = "zfs-exporter";
                static_configs = [
                  {
                    targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.zfs.port}" ];
                    labels = {
                      machine = config.networking.hostName;
                      source = "local";
                      type = "zfs-exporter";
                    };
                  }
                ];
              }
            ]
            ++ lib.optionals config.services.prometheus.exporters.node.enable [
              {
                job_name = "node-exporter";
                static_configs = [
                  {
                    targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
                    labels = {
                      machine = config.networking.hostName;
                      source = "local";
                      type = "node-exporter";
                    };
                  }
                ];
                metric_relabel_configs = [
                  {
                    source_labels = [ "__name__" ];
                    regex = "node_systemd_unit_state";
                    action = "drop";
                  }
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

        services.homepage-dashboard.services = [
          {
            "monitoring" = [
              {
                "VictoriaMetrics" = {
                  href = "https://${localHost}";
                  icon = "victoriametrics.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];
          }
        ];

        # --- gatus ---

        services.gatus.settings.endpoints = [
          {
            name = "VictoriaMetrics";
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
          import authelia
          reverse_proxy ${listenUrl}
        '';

        services.authelia.instances.main.settings.access_control.rules = lib.mkIf autheliaEnabled (
          lib.mkBefore [
            {
              domain = [ localHost ];
              subject = [ "group:admin" ];
              policy = "one_factor";
            }
            {
              domain = [ localHost ];
              policy = "deny";
            }
          ]
        );
      };
    };
}
