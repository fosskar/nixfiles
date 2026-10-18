{ flake-self, ... }:
{
  # static lan nic below; facter would run dhcp on every other nic
  hardware.facter.detected.dhcp.enable = false;

  networking = {
    useDHCP = false;
    nameservers = [ flake-self.router.lan ];
    defaultGateway = {
      address = flake-self.router.lan;
      interface = "end0";
    };

    interfaces.end0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = flake-self.hosts.ha-green.lan;
          prefixLength = 24;
        }
      ];
    };
  };
}
