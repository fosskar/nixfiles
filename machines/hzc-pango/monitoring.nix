_: {

  imports = [
    ../../modules/monitoring/alloy.nix
  ];

  nixfiles.monitoring.alloy.extraConfig = ''
    // relabel instance for all extra scrapes
    prometheus.relabel "instance_label" {
      forward_to = [prometheus.remote_write.mimir.receiver]
      rule {
        target_label = "instance"
        replacement = "hzc-pango"
      }
    }

    // crowdsec metrics
    prometheus.scrape "crowdsec" {
      targets = [{"__address__" = "127.0.0.1:6060"}]
      forward_to = [prometheus.relabel.instance_label.receiver]
      scrape_interval = "15s"
    }

    // traefik metrics
    prometheus.scrape "traefik" {
      targets = [{"__address__" = "127.0.0.1:8082"}]
      forward_to = [prometheus.relabel.instance_label.receiver]
      scrape_interval = "15s"
    }

    // traefik access logs
    local.file_match "traefik_logs" {
      path_targets = [{"__path__" = "/var/log/traefik/access.log"}]
    }

    loki.source.file "traefik_logs" {
      targets = local.file_match.traefik_logs.targets
      forward_to = [loki.process.traefik_labels.receiver]
    }

    loki.process "traefik_labels" {
      stage.static_labels {
        values = {
          job = "traefik-access",
          instance = "hzc-pango",
        }
      }
      forward_to = [loki.write.loki.receiver]
    }
  '';
}
