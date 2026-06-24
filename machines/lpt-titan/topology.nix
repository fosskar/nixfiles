{ lib, config, ... }:
{
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
      network = "lan";
    };
  };
}
