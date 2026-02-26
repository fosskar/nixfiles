{ pkgs, ... }:
{
  # restart vector when pangolin restarts (tunnel connections drop)
  systemd.services.vector = {
    after = [
      "pangolin.service"
      "traefik.service"
      "gerbil.service"
    ];
    bindsTo = [
      "pangolin.service"
      "traefik.service"
      "gerbil.service"
    ];
    partOf = [
      "pangolin.service"
      "traefik.service"
      "gerbil.service"
    ];
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
    };
  };

  # watchdog: restart vector when tunnel recovers but vector is stuck
  # vector doesn't re-establish connections after pangolin tunnel drops
  systemd.services.vector-watchdog = {
    description = "restart vector when sinks recover from errors";
    after = [ "vector.service" ];
    requires = [ "vector.service" ];
    serviceConfig = {
      Type = "oneshot";
    };
    path = [ pkgs.curl ];
    script = ''
      # only act if vector has been logging sink errors recently
      if ! journalctl -u vector.service --since "2 min ago" --no-pager -q \
           | grep -q "Not retriable\|request_failed"; then
        exit 0
      fi

      # check if the tunnel is actually back up (sinks reachable through traefik)
      # victoriametrics returns 204 on successful write, victorialogs returns 200
      vm=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 \
        -X POST http://127.0.0.1:8428/api/v1/write 2>/dev/null || echo "000")
      vl=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 \
        http://127.0.0.1:9428/ 2>/dev/null || echo "000")

      # 404 = traefik has no backend route (tunnel down), don't restart
      if [ "$vm" = "404" ] || [ "$vl" = "404" ]; then
        echo "tunnel still down (vm=$vm vl=$vl), skipping restart"
        exit 0
      fi

      echo "tunnel recovered (vm=$vm vl=$vl), restarting vector"
      systemctl restart vector.service
    '';
  };
  systemd.timers.vector-watchdog = {
    description = "periodically check vector sink health";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "1min";
    };
  };

  # push metrics + logs via pangolin tcp tunnels
  services.vector = {
    enable = true;
    package = pkgs.vector;
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
        # parse traefik json logs, drop localhost requests to break
        # vector→traefik→access.log→vector feedback loop
        parsed_logs = {
          type = "remap";
          inputs = [ "traefik_logs" ];
          source = ''
            . = parse_json!(.message)
            if .ClientHost == "127.0.0.1" { abort }
            .instance = "hzc-pango"
          '';
        };
      };

      sinks = {
        victoriametrics = {
          type = "prometheus_remote_write";
          inputs = [ "labeled_metrics" ];
          endpoint = "http://127.0.0.1:8428/api/v1/write";
          healthcheck.enabled = false;
          buffer = {
            type = "disk";
            max_size = 268435488; # ~256MB (vector minimum)
            when_full = "drop_newest";
          };
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
          buffer = {
            type = "disk";
            max_size = 268435488; # ~256MB (vector minimum)
            when_full = "drop_newest";
          };
        };
      };
    };
  };
}
