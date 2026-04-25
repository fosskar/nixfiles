{
  networking = {
    useDHCP = false;
    defaultGateway = {
      address = "192.168.10.1";
      interface = "enp1s0";
    };
    nameservers = [ "192.168.10.1" ];

    interfaces.enp1s0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.10.240";
          prefixLength = 24;
        }
      ];
    };
  };
}
