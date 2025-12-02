{ config, pkgs, ... }:
{
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

      # prometheus-compatible scrape configuration
      prometheusConfig = {
        scrape_configs = [
          # node exporter - system metrics
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

          # victoriametrics self-monitoring
          {
            job_name = "victoriametrics";
            static_configs = [
              {
                targets = [ "localhost:8428" ];
              }
            ];
          }

          # nut exporter
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

  # install nut client tools for testing
  environment.systemPackages = [ pkgs.nut ];

  services.prometheus.exporters = {
    nut = {
      enable = true;
      port = 9199;
      listenAddress = "127.0.0.1";
      openFirewall = false;
      nutServer = "127.0.0.1";
    };
  };

  services.grafana = {
    enable = true;
    package = pkgs.grafana;

    openFirewall = false;

    # install victoriametrics datasource plugin (for advanced features)
    declarativePlugins = with pkgs.grafanaPlugins; [
      victoriametrics-metrics-datasource
      victoriametrics-logs-datasource
    ];

    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
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
        org_name = "main";
        org_role = "Viewer";
        hide_version = true;
      };
      "auth.generic_oauth" = {
        enabled = true;
        auto_login = false;
        name = "Pocket-ID";
        icon = "signin";
        client_id = "$__file{${config.sops.secrets."grafana-oidc-client-id".path}}";
        client_secret = "$__file{${config.sops.secrets."grafana-oidc-client-secret".path}}";
        scopes = [
          "openid"
          "email"
          "profile"
        ];
        auth_url = "https://auth.simonoscar.me/authorize";
        token_url = "https://auth.simonoscar.me/api/oidc/token";
        api_url = "https://auth.simonoscar.me/api/oidc/userinfo";
        email_attribute_name = "email:primary";
        allow_sign_up = false;
        skip_org_role_sync = true;
        allow_assign_grafana_admin = true;
        name_attribute_path = "name";
        email_attribute_path = "email";
        login_attribute_path = "preferred_username";
        use_pkce = true;
      };
    };

    # note: datasource must be added manually via grafana ui after startup
    # declarative provisioning of external plugin types fails because
    # plugins load after provisioning runs
    provision = {
      enable = true;

      datasources.settings = {
        datasources = [
          #{
          #  name = "victoriametrics";
          #  type = "prometheus";
          #  access = "proxy";
          #  url = "http://localhost:8428";
          #  isDefault = true;
          #}
          {
            name = "victoriametrics";
            type = "victoriametrics-metrics-datasource";
            access = "proxy";
            url = "http://localhost:8428";
            isDefault = true;
          }
          {
            name = "VictoriaLogs";
            type = "victoriametrics-logs-datasource";
            access = "proxy";
            url = "http://localhost:9428";
          }
        ];
      };
      # provision default dashboards
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
