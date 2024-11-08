_: {
  networking = {
    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [
        80
        443
        6443 # yes kapi
        4240
        #2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
        #2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
      ];
      allowedUDPPorts = [
        8472 # for vxlan
        6081 # for Geneve
      ];
    };
  };
}
