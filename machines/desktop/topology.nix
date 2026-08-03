{ lib, config, ... }:
{
  topology.self = {
    icon = "devices.desktop";
    hardware.info = "workstation";
    interfaces.lan = {
      addresses = [
        (lib.head (
          lib.splitString "/" config.networking.networkmanager.ensureProfiles.profiles.lan.ipv4.address1
        ))
      ];
      network = "lan";
    };
  };
}
