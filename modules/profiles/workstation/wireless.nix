{ lib, config, ... }:
{
  # wireless regulatory database - helps with channel selection
  hardware.wirelessRegulatoryDatabase = true;

  # persist iwd network profiles with impermanence
  nixfiles.impermanence.directories = lib.mkIf config.nixfiles.impermanence.enable [
    "/var/lib/iwd"
  ];

  # iwd settings (iwd enabled via networkmanager.nix)
  networking.wireless.iwd.settings = {
    Scan.DisablePeriodicScan = true;
    Settings.AutoConnect = true;

    General = {
      AddressRandomization = "network";
      AddressRandomizationRange = "full";
      EnableNetworkConfiguration = true;
      RoamRetryInterval = 15;
    };

    Network = {
      EnableIPv6 = true;
      RoutePriorityOffset = 300;
    };
  };
}
