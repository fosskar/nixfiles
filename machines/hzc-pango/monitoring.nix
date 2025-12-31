{ pkgs, ... }:
{
  # restart vector when traefik restarts (tunnel connections drop)
  systemd.services.vector = {
    after = [ "traefik.service" ];
    partOf = [ "traefik.service" ];
  };

  # restart vector after traefik starts (for nixos-rebuild)
  systemd.services.traefik.serviceConfig.ExecStartPost =
    "${pkgs.bash}/bin/bash -c 'sleep 5 && ${pkgs.systemd}/bin/systemctl restart vector.service || true'";

  # push metrics + logs via pangolin tcp tunnels
  services.vector = {
    enable = true;
    package = pkgs.stable.vector; # FIXME
    settings = {
      # metrics sources
      sources = {
        crowdsec_metrics = {
          type = "prometheus_scrape";
          endpoints = [ "http://127.0.0.1:6060/metrics" ];
          scrape_interval_secs = 15;
        };
        traefik_metrics = {
          type = "prometheus_scrape";
          endpoints = [ "http://127.0.0.1:8082/metrics" ];
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
          endpoint = "http://127.0.0.1:8428/api/v1/write";
        };
        victorialogs = {
          type = "http";
          inputs = [ "parsed_logs" ];
          uri = "http://127.0.0.1:9428/insert/jsonline?_stream_fields=instance&_msg_field=RequestPath&_time_field=StartUTC";
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
