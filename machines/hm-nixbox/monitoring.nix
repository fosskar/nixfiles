{ config, pkgs, ... }:
{
  imports = [
    ../../modules/monitoring
  ];

  monitoring = {
    enable = true;
    enableNodeExporter = true;
    enableNutExporter = false;
    enableResticExporter = false;
  };

  services = {
    victorialogs.enable = true;

    victoriametrics = {
      enable = true;
      listenAddress = "127.0.0.1:8428";
      retentionPeriod = "3"; # 3 months

      # extra options
      extraOptions = [
        "-promscrape.dropOriginalLabels=false" # show discovered target labels
        "-selfScrapeInterval=10s"
      ];

      prometheusConfig = {
        scrape_configs = [
          {
            job_name = "node-exporter";
            static_configs = [
              {
                targets = [
                  "localhost:9100"
                  "192.168.10.1:9100" # router
                  "192.168.10.2:9100" # ap
                ];
                labels.type = "node-exporter";
              }
            ];
          }

          {
            job_name = "victoriametrics";
            static_configs = [
              {
                targets = [ "localhost:8428" ];
              }
            ];
          }

          {
            job_name = "nut-exporter";
            static_configs = [
              {
                targets = [ "localhost:9199" ];
                labels = {
                  ups = "eaton-ellipse";
                  type = "nut-exporter";
                };
              }
            ];
            metrics_path = "/ups_metrics";
            params = {
              ups = [ "eaton-ellipse" ];
            };
          }

          ## zfs exporter
          #{
          #  job_name = "zfs-exporter";
          #  static_configs = [
          #    {
          #      targets = [ "localhost:9199" ];
          #      labels = {
          #        ups = "eaton-ellipse";
          #        type = "nut-exporter";
          #      };
          #    }
          #  ];
          #  metrics_path = "/ups_metrics";
          #  params = {
          #    ups = [ "eaton-ellipse" ];
          #  };
          #}
        ];
      };
    };
  };

  # install nut client tools
  environment.systemPackages = [ pkgs.nut ];

  services.grafana = {
    enable = true;
    package = pkgs.grafana;

    openFirewall = false;
    declarativePlugins = with pkgs.grafanaPlugins; [
      victoriametrics-metrics-datasource
      victoriametrics-logs-datasource
    ];

    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3100;
        domain = "grafana.osscar.me";
        root_url = "https://grafana.osscar.me";
      };

      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
      };

      security = {
        admin_user = "admin";
        cookie_secure = true;
        admin_password = "$__file{${config.sops.secrets."admin-password".path}}";
      };

      users = {
        allow_signup = false;
      };

      auth = {
        disable_login_form = true;
      };

      "auth.anonymous" = {
        enabled = true;
        org_id = 1;
        org_role = "Admin";
        hide_version = true;
      };
    };

    provision = {
      enable = true;

      datasources.settings = {
        #deleteDatasources = [
        #  { name = "victoriametrics"; orgId = 1; }
        #];
        datasources = [
          {
            name = "VictoriaMetrics";
            type = "prometheus";
            access = "proxy";
            url = "http://localhost:8428";
            isDefault = true;
          }
          {
            name = "VictoriaMetrics (native)";
            type = "victoriametrics-metrics-datasource";
            access = "proxy";
            url = "http://localhost:8428";
            isDefault = false;
          }
          {
            name = "VictoriaLogs";
            type = "victoriametrics-logs-datasource";
            access = "proxy";
            url = "http://localhost:9428";
          }
        ];
      };

      dashboards.settings = {
        apiVersion = 1;
        providers = [
          {
            name = "default";
            orgId = 1;
            folder = "";
            type = "file";
            disableDeletion = false;
            editable = true;
            options = {
              path = "/var/lib/grafana/dashboards";
            };
          }
        ];
      };
    };
  };
}
