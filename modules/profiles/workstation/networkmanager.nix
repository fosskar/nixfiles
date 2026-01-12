{ lib, config, ... }:
{
  # add wheel users to networkmanager group
  users.groups.networkmanager.members = config.users.groups.wheel.members;

  # wireless regulatory database
  hardware.wirelessRegulatoryDatabase = true;

  # persist networkmanager + iwd state
  nixfiles.persistence.directories = [
    "/var/lib/NetworkManager"
    "/var/lib/iwd"
  ];

  networking = {
    networkmanager = {
      enable = lib.mkDefault true;
      # use systemd-resolved for DNS (enabled in base/network.nix)
      dns = lib.mkDefault "systemd-resolved";
      # iwd backend with privacy defaults
      wifi = {
        backend = lib.mkDefault "iwd";
        macAddress = lib.mkDefault "random";
        powersave = lib.mkDefault true;
        scanRandMacAddress = lib.mkDefault true;
      };
    };

    # iwd settings
    wireless.iwd.settings = {
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

    # fallback dns servers (privacy-focused, non-us)
    nameservers = [
      # mullvad swedish
      "194.242.2.2"
      "2a07:e340::2"
      # dns.sb germany
      "45.11.45.11"
      "185.222.222.222"
      "2a11::"
      "2a09::"
      # quad9 swiss
      "9.9.9.9"
      "149.112.112.112"
      "2620:fe::fe"
      "2620:fe::9"
    ];
  };
}
