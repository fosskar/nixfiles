_: {
  # wireless regulatory database - helps with channel selection
  hardware.wirelessRegulatoryDatabase = true;

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
