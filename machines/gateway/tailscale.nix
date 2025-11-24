_: {
  services = {
    tailscale = {
      enable = true;
      openFirewall = true;
      extraSetFlags = [ "--advertise-routes=10.0.0.0/24,192.168.10.0/24" ];
      interfaceName = "userspace-networking"; # The interface name for tunnel traffic. Use “userspace-networking” (beta) to not use TUN.
    };
  };

  # enable ip forwarding for tailscale subnet routing
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };
}
