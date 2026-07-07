{ flake-self, ... }:
{
  topology.self = {
    icon = "devices.cloud-server";
    hardware.info = "hetzner vps";
    interfaces.wan = {
      addresses = [ flake-self.hosts.gateway.wan ];
      network = "wan";
    };
    services.wireguard = {
      name = "WireGuard";
      info = "controller :51820";
    };
  };
}
