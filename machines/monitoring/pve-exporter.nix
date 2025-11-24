{ config, ... }:
{
  # prometheus pve exporter - scrapes proxmox host for lxc/vm metrics
  services.prometheus.exporters.pve = {
    enable = true;
    port = 9221;
    listenAddress = "localhost";
    openFirewall = true;

    collectors = {
      cluster = false;
      config = true;
      node = true;
      replication = false;
      resources = true;
      status = true;
      version = true;
    };

    # use environment file for credentials (safer than config file)
    environmentFile = config.age.secrets.pve-exporter-env.path;
  };
}
