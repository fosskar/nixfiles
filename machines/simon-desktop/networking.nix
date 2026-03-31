{
  networking = {
    hostName = "simon-desktop";

    useDHCP = false;

    defaultGateway = {
      address = "192.168.10.1";
      interface = "enp14s0";
    };
    nameservers = [ "192.168.10.1" ];

    interfaces.enp14s0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.10.100";
          prefixLength = 24;
        }
      ];
    };
  };
}
