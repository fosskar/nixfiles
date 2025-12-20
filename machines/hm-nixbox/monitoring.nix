{
  config,
  pkgs,
  lib,
  ...
}:
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

  # grant beszel-agent disk access for SMART monitoring
  systemd.services.beszel-agent = {
    unitConfig.RequiresMountsFor = [ "/tank" ];
    serviceConfig = {
      # smart data
      AmbientCapabilities = "CAP_SYS_RAWIO CAP_SYS_ADMIN";
      CapabilityBoundingSet = "CAP_SYS_RAWIO CAP_SYS_ADMIN";
      SupplementaryGroups = [ "disk" ];
      PrivateUsers = lib.mkForce false;
      NoNewPrivileges = lib.mkForce false;
    };
  };

  services = {
    beszel = {
      hub = {
        enable = true;
        #package = pkgs.custom.beszel;
        host = "127.0.0.1";
        port = 8090;
      };
      agent = {
        enable = true;
        environment = {
          LISTEN = "45876";
          SENSORS = "-nct6798_cputin,-nct6798_auxtin0,-nct6798_auxtin2,-nct6798_auxtin4"; # exclude broken phantom sensor
          FILESYSTEM = "/persist";
          EXTRA_FILESYSTEMS = "/nix__Nix,/tank/apps__Apps,/tank/media__Media,/tank/shares__Shares,/tank/backup__Backup";
          #SERVICE_PATTERNS = "pangolin*,traefik*,jellyfin*,immich*,grafana*,ollama*,*arr*,beszel*,newt*";
          #INTEL_GPU_DEVICE = "drm:/dev/dri/card1";
        };
        environmentFile = config.sops.secrets."beszel.env".path;
        extraPath = [
          pkgs.intel-gpu-tools
          pkgs.smartmontools # for SMART disk health data
        ];
      };
    };

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
