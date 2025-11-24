_: {
  networking = {
    firewall = {
      enable = true;
      allowPing = true;
      logRefusedConnections = false;
      trustedInterfaces = [
        "tailscale0"
      ];
    };
    nftables = {
      enable = true;
    };
  };
}
