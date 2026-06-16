{ lib, config, ... }:
{
  networking.networkmanager.ensureProfiles.profiles."home" = {
    ipv4 = {
      method = "manual";
      address1 = "192.168.10.150/24,192.168.10.1";
      dns = "192.168.10.1;";
    };
    ipv6.method = "auto";
  };

  # derive address from the networkmanager profile ("ip/cidr,gateway")
  # wifi client: reaches the lan through the dumb AP (see modules/nixos/topology.nix)
  topology.self = {
    icon = "devices.laptop";
    hardware.info = "laptop";
    interfaces.wlan = {
      type = "wifi";
      addresses = [
        (lib.head (
          lib.splitString "/" config.networking.networkmanager.ensureProfiles.profiles.home.ipv4.address1
        ))
      ];
      network = "home";
    };
  };
}
