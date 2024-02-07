{
  config,
  pkgs,
  ...
}: {
  services.prometheus = {
    enable = true;
    port = 9001;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = ["systemd"];
        port = 9002;
      };
      unbound = {
        enable = true;
        controlInterface = "/run/unbound/unbound.ctl";
        unbound.host = "unix:///run/unbound/unbound.ctl";
        user = "unbound";
        port = 9003;
      };
    };
    scrapeConfigs = [
      {
        job_name = "node-exporter";
        static_configs = [
          {
            targets = ["127.0.0.1:${toString config.services.prometheus.exporters.node.port}"];
          }
        ];
      }
      {
        job_name = "unbound";
        static_configs = [
          {
            targets = ["127.0.0.1:${toString config.services.prometheus.exporters.unbound.port}"];
          }
        ];
      }
    ];
  };

  services.loki = {
    enable = true;
    configuration = {
      server.http_listen_port = 3030;
      auth_enabled = false;

      common = {
        replication_factor = 1;
        ring = {
          kvstore.store = "inmemory";
          instance_addr = "127.0.0.1";
        };
      };

      ingester = {
        chunk_encoding = "snappy";
        lifecycler = {
          address = "127.0.0.1";
          ring = {
            kvstore = {
              store = "inmemory";
            };
            replication_factor = 1;
          };
        };
        chunk_idle_period = "1h";
        max_chunk_age = "1h";
        chunk_target_size = 1048576;
        chunk_retain_period = "30s";
        max_transfer_retries = 0;
      };

      limits_config = {
        retention_period = "120h";
        ingestion_burst_size_mb = 16;
        ingestion_rate_mb = 10;
        reject_old_samples = true;
        reject_old_samples_max_age = "24h";
      };

      table_manager = {
        retention_deletes_enabled = false;
        retention_period = "120h";
      };

      compactor = {
        retention_enabled = true;
        compaction_interval = "10m";
        working_directory = "/var/lib/loki";
        shared_store = "filesystem";
        delete_request_cancel_period = "10m";
        retention_delete_delay = "2h";
        retention_delete_worker_count = 150;
        compactor_ring = {
          kvstore = {
            store = "inmemory";
          };
        };
      };

      schema_config = {
        configs = [
          {
            from = "2024-01-01";
            store = "boltdb-shipper";
            object_store = "filesystem";
            schema = "v12";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };

      storage_config = {
        boltdb_shipper = {
          active_index_directory = "/var/lib/loki/boltdb-shipper-active";
          cache_location = "/var/lib/loki/boltdb-shipper-cache";
          cache_ttl = "24h";
          shared_store = "filesystem";
        };

        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };
      query_scheduler = {
        max_outstanding_requests_per_tenant = 8192;
      };
    };
  };

  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 3031;
        grpc_listen_port = 0;
      };
      positions = {
        filename = "/tmp/positions.yaml";
      };
      clients = [
        {
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
        }
      ];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = "voyager";
            };
          };
          relabel_configs = [
            {
              source_labels = ["__journal__systemd_unit"];
              target_label = "unit";
            }
          ];
        }
        {
          job_name = "unbound";
          static_configs = [
            {
              targets = ["localhost"];
              labels = {
                host = "voyager";
                job = "unbound";
                __path__ = "/var/lib/unbound/unbound.log";
              };
            }
          ];
          pipeline_stages = [
            {
              labeldrop = ["filename"];
            }
            {
              match = {
                selector = ''
                  {job="unbound"} |~ " start | stopped |.*in-addr.arpa."
                '';
                action = "drop";
              };
            }
            {
              match = {
                selector = ''
                  {job="unbound"} |= "reply:"
                '';
                stages = [
                  {
                    static_labels = {
                      dns = "reply";
                    };
                  }
                ];
              };
            }
            {
              match = {
                selector = ''
                  {job="unbound"} |~ "redirect |always_null|always_nxdomain"
                '';
                stages = [
                  {
                    static_labels = {
                      dns = "block";
                    };
                  }
                ];
              };
            }
          ];
        }
      ];
    };
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 2342;
        http_addr = "127.0.0.1";
        domain = "grafana.space";
        root_url = "http://grafana.space";
      };
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          uid = "PDOVLC8AT2RK0PW3";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
          editable = false;
        }
        {
          name = "Loki";
          type = "loki";
          uid = "LD9DH35SKJ65DS3K";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
          editable = false;
        }
      ];
      dashboards.settings.providers = [
        {
          name = "system";
          folder = "";
          type = "file";
          options.path = ./dashboards;
        }
      ];
    };
  };
  # nginx reverse proxy
  services.nginx = {
    enable = true;
    additionalModules = [pkgs.nginxModules.pam];
    recommendedProxySettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    # recommendedTlsSettings = true;
    upstreams = {
      "grafana" = {
        servers = {
          "127.0.0.1:${toString config.services.grafana.settings.server.http_port}" = {};
        };
      };
      "prometheus" = {
        servers = {
          "127.0.0.1:${toString config.services.prometheus.port}" = {};
        };
      };
      "loki" = {
        servers = {
          "127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}" = {};
        };
      };
      "promtail" = {
        servers = {
          "127.0.0.1:${toString config.services.promtail.configuration.server.http_listen_port}" = {};
        };
      };
    };
    virtualHosts."grafana.space" = {
      locations."/" = {
        proxyPass = "http://grafana";
        proxyWebsockets = true;
      };
      extraConfig = ''
        auth_pam  "Password Required";
        auth_pam_service_name "nginx";
      '';
      listen = [
        {
          addr = "192.168.178.91";
          port = 80;
        }
      ];
    };
    virtualHosts."prometheus.space" = {
      locations."/" = {
        proxyPass = "http://prometheus";
        proxyWebsockets = true;
      };
      extraConfig = ''
        auth_pam  "Password Required";
        auth_pam_service_name "nginx";
      '';
      listen = [
        {
          addr = "192.168.178.91";
          port = 80;
        }
      ];
    };
    # confirm with http://192.168.178.91:8030/loki/api/v1/status/buildinfo
    #     (or)     /config /metrics /ready
    virtualHosts."loki.space" = {
      locations."/" = {
        proxyPass = "http://loki";
        proxyWebsockets = true;
      };
      extraConfig = ''
        auth_pam  "Password Required";
        auth_pam_service_name "nginx";
      '';
      listen = [
        {
          addr = "192.168.178.91";
          port = 80;
        }
      ];
    };
    virtualHosts."promtail.space" = {
      locations."/" = {
        proxyPass = "http://promtail";
        proxyWebsockets = true;
      };
      extraConfig = ''
        auth_pam  "Password Required";
        auth_pam_service_name "nginx";
      '';
      listen = [
        {
          addr = "192.168.178.91";
          port = 80;
        }
      ];
    };
  };
}
