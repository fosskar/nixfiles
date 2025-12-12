_: {
  networking = {
    hostName = "hm-nixbox";
    hostId = "25e85037"; # zfs requires unique hostId

    useDHCP = false;
    defaultGateway = {
      address = "192.168.10.1";
      interface = "enp36s0f0np0";
    };
    nameservers = [ "192.168.10.1" ];

    interfaces.enp36s0f0np0.ipv4.addresses = [
      {
        address = "192.168.10.80";
        prefixLength = 24;
      }
    ];

    firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
