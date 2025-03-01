_: {
  networking = {
    firewall = {
      enable = true;
      allowPing = true;
      trustedInterfaces = [
        "tailscale0"
      ];
    };
    nftables = {
      enable = true;
    };
  };
}
