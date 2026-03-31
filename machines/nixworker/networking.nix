{
  networking = {
    hostName = "nixworker";

    useDHCP = false;
    nameservers = [ "192.168.10.1" ];
    defaultGateway = {
      address = "192.168.10.1";
      interface = "bond0";
    };

    bonds.bond0 = {
      interfaces = [
        "enp3s0"
        "enp4s0"
      ];
      driverOptions = {
        mode = "active-backup";
        miimon = "100";
        primary = "enp3s0";
      };
    };

    interfaces.bond0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.10.210";
          prefixLength = 24;
        }
      ];
    };
  };
}
