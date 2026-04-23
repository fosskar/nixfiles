{
  flake.modules.nixos.vector =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      instance = config.networking.hostName;
      crowdsecMetricsEndpoint = "http://127.0.0.1:6060/metrics";
      traefikMetricsEndpoint = "http://127.0.0.1:8082/metrics";
      traefikAccessLogPath = "/var/log/traefik/access.log";
      victoriametricsEndpoint = "http://127.0.0.1:8428/api/v1/write";
      victorialogsEndpoint = "http://127.0.0.1:9428/insert/jsonline?_stream_fields=instance&_msg_field=RequestPath&_time_field=StartUTC";
    in
    {
      config = lib.mkIf config.services.vector.enable {
        services.vector = {
          package = pkgs.vector;
          settings = {
            sources = {
              crowdsec_metrics = {
                type = "prometheus_scrape";
                endpoints = [ crowdsecMetricsEndpoint ];
                scrape_interval_secs = 15;
              };

              traefik_metrics = {
                type = "prometheus_scrape";
                endpoints = [ traefikMetricsEndpoint ];
                scrape_interval_secs = 15;
              };

              traefik_logs = {
                type = "file";
                include = [ traefikAccessLogPath ];
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
                endpoint = victoriametricsEndpoint;
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
                uri = victorialogsEndpoint;
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
