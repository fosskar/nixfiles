{ config, pkgs, ... }:
{
  imports = [
    ../../modules/monitoring
  ];

  monitoring.telegraf = {
    enable = true;
    plugins = [
      "system"
      "systemd"
      "zfs"
      "upsd"
      "sensors"
      "smart"
    ];
  };

  monitoring.exporter = {
    enable = true;
    enableZfsExporter = true;
  };

  services = {
    victorialogs.enable = true;

    victoriametrics = {
      enable = true;
      listenAddress = "127.0.0.1:8428"; # accessible from local network  and pangolin tunnel
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
                  "192.168.10.1:9100" # router
                  "192.168.10.2:9100" # ap
                ];
                labels.type = "node-exporter";
              }
            ];
          }

          {
            job_name = "telegraf";
            static_configs = [
              {
                targets = [ "localhost:9273" ];
                labels.type = "telegraf";
              }
            ];
          }

          {
            job_name = "zfs-exporter";
            static_configs = [
              {
                targets = [ "localhost:9134" ];
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

          # openwrt telegraf (unbound + adguard home)
          {
            job_name = "openwrt-telegraf";
            static_configs = [
              {
                targets = [ "192.168.10.1:9273" ];
                labels = {
                  type = "telegraf";
                };
              }
            ];
          }
        ];
      };
    };
  };

  # install nut client tools
  environment.systemPackages = [ pkgs.nut ];

  # provision grafana dashboards via /etc
  environment.etc = builtins.listToAttrs (
    map (file: {
      name = "grafana-dashboards/${file}";
      value.source = ./dashboards/${file};
    }) (builtins.attrNames (builtins.readDir ./dashboards))
  );

  services.grafana = {
    enable = true;
    #package = pkgs.grafana;

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
        enable_gzip = true;
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

      # experimental: try new layout system to avoid react-grid-layout freeze bugs
      "feature_toggles" = {
        #dashboardNewLayouts = true;
      };
    };

    provision = {
      enable = true;

      datasources.settings = {
        #deleteDatasources = [ ];
        datasources = [
          {
            name = "VictoriaMetrics";
            type = "prometheus";
            access = "proxy";
            url = "http://localhost:8428";
            isDefault = true;
          }
          # temporarily disabled - causing browser slowdown
          #{
          #  name = "VictoriaLogs";
          #  type = "victoriametrics-logs-datasource";
          #  access = "proxy";
          #  url = "http://localhost:9428";
          #}
        ];
      };

      dashboards.settings = {
        apiVersion = 1;
        providers = [
          {
            name = "nixos";
            orgId = 1;
            #folder = "NixOS";
            type = "file";
            disableDeletion = true;
            editable = true;
            options = {
              path = "/etc/grafana-dashboards";
            };
          }
        ];
      };
    };
  };
}
