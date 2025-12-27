_: {
  # push metrics + logs via pangolin tcp tunnels
  services.vector = {
    enable = true;
    settings = {
      # metrics sources
      sources = {
        crowdsec_metrics = {
          type = "prometheus_scrape";
          endpoints = [ "http://localhost:6060/metrics" ];
          scrape_interval_secs = 15;
        };
        traefik_metrics = {
          type = "prometheus_scrape";
          endpoints = [ "http://localhost:8082/metrics" ];
          scrape_interval_secs = 15;
        };
        # log source
        traefik_logs = {
          type = "file";
          include = [ "/var/log/traefik/access.log" ];
        };
      };

      transforms = {
        # add instance label to metrics
        labeled_metrics = {
          type = "remap";
          inputs = [
            "crowdsec_metrics"
            "traefik_metrics"
          ];
          source = ''
            .tags.instance = "hzc-pango"
          '';
        };
        # parse traefik json logs for victorialogs
        parsed_logs = {
          type = "remap";
          inputs = [ "traefik_logs" ];
          source = ''
            . = parse_json!(.message)
            .instance = "hzc-pango"
          '';
        };
      };

      sinks = {
        victoriametrics = {
          type = "prometheus_remote_write";
          inputs = [ "labeled_metrics" ];
          endpoint = "http://localhost:8428/api/v1/write";
        };
        victorialogs = {
          type = "http";
          inputs = [ "parsed_logs" ];
          uri = "http://localhost:9428/insert/jsonline?_stream_fields=instance&_msg_field=RequestPath&_time_field=StartUTC";
          encoding = {
            codec = "json";
          };
          framing.method = "newline_delimited";
          healthcheck.enabled = false;
        };
      };
    };
  };
}
