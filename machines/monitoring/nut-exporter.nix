{ pkgs, ... }:
{
  # install nut client tools for testing
  environment.systemPackages = [ pkgs.nut ];

  services.prometheus.exporters.nut = {
    enable = true;
    port = 9199;
    listenAddress = "localhost";
    openFirewall = true;
    nutServer = "10.0.0.1"; # proxmox host with nut server
    # no authentication - read-only monitoring
  };
}
