{ flake-self, ... }:
{
  networking = {
    hostId = "25e85037"; # zfs requires unique hostId

    useDHCP = false;
    defaultGateway = {
      address = flake-self.router.srv;
      interface = "enp36s0f0np0";
    };
    nameservers = [ flake-self.router.srv ];

    interfaces.enp36s0f0np0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = flake-self.hosts.nixbox.lan;
          prefixLength = 24;
        }
      ];
    };
  };

  systemd.network.networks = {
    # clan sets multicastdns on these defaults without a match section.
    "99-ethernet-default-dhcp".enable = false;
    "99-wireless-client-dhcp".enable = false;
  };
}
