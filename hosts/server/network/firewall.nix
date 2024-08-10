_: {
  networking = {
    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [
        53
        80
        443
        6443
      ];
      allowedUDPPorts = [ 53 ];
    };
  };
}
