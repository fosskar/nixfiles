{ lib, config, ... }:
{
  networking = {
    networkmanager.ensureProfiles.profiles."lan" = {
      connection = {
        id = "lan";
        type = "ethernet";
        autoconnect = true;
      };
      ipv4 = {
        method = "manual";
        address1 = "192.168.10.100/24,192.168.10.1";
        dns = "192.168.10.1;";
      };
      ipv6.method = "auto";
    };
  };

  # derive address from the networkmanager profile ("ip/cidr,gateway")
  topology.self = {
    hardware.info = "workstation";
    interfaces.lan = {
      addresses = [
        (lib.head (
          lib.splitString "/" config.networking.networkmanager.ensureProfiles.profiles.lan.ipv4.address1
        ))
      ];
      network = "home";
    };
  };
}
