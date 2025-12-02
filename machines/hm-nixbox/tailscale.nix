{
  services = {
    tailscale = {
      enable = true;
      openFirewall = true;
      interfaceName = "userspace-networking"; # The interface name for tunnel traffic. Use “userspace-networking” (beta) to not use TUN.
    };
  };
}
