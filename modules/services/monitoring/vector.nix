{
  flake.modules.nixos.vector =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.nixfiles.monitoring.vector;
      instance = if cfg.instance != null then cfg.instance else config.networking.hostName;
    in
    {
      # --- options ---

      options.nixfiles.monitoring.vector = {
        enable = lib.mkEnableOption "vector log+metrics shipper";

        instance = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "instance label value for shipped data";
        };

        crowdsecMetricsEndpoint = lib.mkOption {
          type = lib.types.str;
          default = "http://127.0.0.1:6060/metrics";
          description = "crowdsec prometheus metrics endpoint";
        };

        traefikMetricsEndpoint = lib.mkOption {
          type = lib.types.str;
          default = "http://127.0.0.1:8082/metrics";
          description = "traefik prometheus metrics endpoint";
        };

        traefikAccessLogPath = lib.mkOption {
          type = lib.types.str;
          default = "/var/log/traefik/access.log";
          description = "traefik access log path";
        };

        victoriametricsEndpoint = lib.mkOption {
          type = lib.types.str;
          default = "http://127.0.0.1:8428/api/v1/write";
          description = "victoriametrics remote_write endpoint";
        };

        victorialogsEndpoint = lib.mkOption {
          type = lib.types.str;
          default = "http://127.0.0.1:9428/insert/jsonline?_stream_fields=instance&_msg_field=RequestPath&_time_field=StartUTC";
          description = "victorialogs jsonline ingest endpoint";
        };
      };

      # --- service ---

      config = lib.mkIf cfg.enable {
        services.vector = {
          enable = true;
          package = pkgs.vector;
          settings = {
            sources = {
              crowdsec_metrics = {
                type = "prometheus_scrape";
                endpoints = [ cfg.crowdsecMetricsEndpoint ];
                scrape_interval_secs = 15;
              };

              traefik_metrics = {
                type = "prometheus_scrape";
                endpoints = [ cfg.traefikMetricsEndpoint ];
                scrape_interval_secs = 15;
              };

              traefik_logs = {
                type = "file";
                include = [ cfg.traefikAccessLogPath ];
              };
            };

            transforms = {
              labeled_metrics = {
                type = "remap";
                inputs = [
                  "crowdsec_metrics"
                  "traefik_metrics"
                ];
                source = ''
                  .tags.instance = "${instance}"
                '';
              };

              parsed_logs = {
                type = "remap";
                inputs = [ "traefik_logs" ];
                source = ''
                  . = parse_json!(.message)
                  if .ClientHost == "127.0.0.1" { abort }
                  .instance = "${instance}"
                '';
              };
            };

            sinks = {
              victoriametrics = {
                type = "prometheus_remote_write";
                inputs = [ "labeled_metrics" ];
                endpoint = cfg.victoriametricsEndpoint;
                healthcheck.enabled = false;
                buffer = {
                  type = "disk";
                  max_size = 268435488;
                  when_full = "drop_newest";
                };
              };

              victorialogs = {
                type = "http";
                inputs = [ "parsed_logs" ];
                uri = cfg.victorialogsEndpoint;
                encoding.codec = "json";
                framing.method = "newline_delimited";
                healthcheck.enabled = false;
                buffer = {
                  type = "disk";
                  max_size = 268435488;
                  when_full = "drop_newest";
                };
              };
            };
          };
        };
      };
    };
}
