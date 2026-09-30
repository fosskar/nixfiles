{ flake-self, ... }:
{
  # hetzner cloud does not hand out ipv6 over dhcp or slaac; the primary /64
  # has to be configured statically
  networking = {
    interfaces.eth0.ipv6.addresses = [
      {
        address = flake-self.hosts.gateway.wan6;
        prefixLength = 64;
      }
    ];
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
  };
}
