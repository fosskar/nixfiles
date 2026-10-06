{ flake-self, ... }:
{
  networking = {
    useDHCP = false;
    nameservers = [ flake-self.router.srv ];
    defaultGateway = {
      address = flake-self.router.srv;
      interface = "enp5s0f0np0";
    };

    interfaces.enp5s0f0np0 = {
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
