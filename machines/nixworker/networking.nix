{ flake-self, ... }:
{
  networking = {
    useDHCP = false;
    nameservers = [ flake-self.router.srv ];
    defaultGateway = {
      address = flake-self.router.srv;
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
          address = flake-self.hosts.nixworker.lan;
          prefixLength = 24;
        }
      ];
    };
  };
}
