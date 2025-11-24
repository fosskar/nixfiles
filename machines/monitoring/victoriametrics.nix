{ ... }:
{
  networking.firewall.allowedTCPPorts = [
    8428 # victoriametrics http api
  ];

  services.victoriametrics = {
    enable = true;
    listenAddress = "0.0.0.0:8428";
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
                "192.168.10.1:9100" # router
                "192.168.10.2:9100" # ap
                "10.0.0.98:9100" # backup
                "10.0.0.100:9100" # gateway
                "10.0.0.101:9100" # reverseproxy
                "10.0.0.102:9100" # monitoring (self)
                "10.0.0.103:9100" # dashboard
                "10.0.0.104:9100" # fileserver
                "10.0.0.105:9100" # oidc
                "10.0.0.106:9100" # llm
                "10.0.0.107:9100" # immich
                "10.0.0.108:9100" # paperless
                "10.0.0.109:9100" # vaultwarden
                "10.0.0.110:9100" # arr
                "10.0.0.111:9100" # media
                "10.0.0.112:9100" # nextcloud
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

        # proxmox pve exporter - container/vm metrics from proxmox host
        {
          job_name = "pve-exporter";
          static_configs = [
            {
              targets = [
                "localhost:9221"
              ];
              labels.type = "pve-exporter";
            }
          ];
          metrics_path = "/pve";
          params = {
            target = [ "10.0.0.1" ];
          };
        }

        # nut exporter - ups metrics from proxmox nut server
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
      ];
    };
  };
}
