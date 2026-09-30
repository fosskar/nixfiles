{ flake-self, ... }:
{
  # facter would set networking.interfaces.eth0.useDHCP, and nixos forces
  # that to DHCP=yes; hetzner cloud serves only ipv4 over dhcp
  hardware.facter.detected.dhcp.enable = false;

  # hetzner cloud does not hand out ipv6 over dhcp or slaac; the primary /64
  # has to be configured statically
  systemd.network.networks."40-eth0" = {
    matchConfig.Name = "eth0";
    networkConfig.DHCP = "ipv4";
    address = [ "${flake-self.hosts.gateway.wan6}/64" ];
    routes = [ { Gateway = "fe80::1"; } ];
  };
}
