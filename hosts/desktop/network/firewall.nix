_: {
  networking = {
    firewall = {
      enable = true;
      trustedInterfaces = [
        "tailscale0"
        "virbr0"
        "virbr1"
        "vnet0"
      ];
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
    };
    nftables = {
      enable = true;
    };
  };
}
