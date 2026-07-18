{
  flake.modules.nixos.workstation =
    { lib, config, ... }:
    {
      users.groups.networkmanager.members = lib.mkAfter config.users.groups.wheel.members;

      hardware.wirelessRegulatoryDatabase = true;

      networking = {
        useDHCP = lib.mkDefault false;
        dhcpcd.enable = lib.mkDefault false;
        useNetworkd = lib.mkForce false;

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

        networkmanager = {
          enable = lib.mkDefault true;
          # use systemd-resolved for DNS (enabled in base/network.nix)
          dns = lib.mkDefault "systemd-resolved";
          # on workstations, let NM manage normal desktop interfaces incl ethernet
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
          # nm drives autoconnect; iwd autoconnect races nm-ensure-profiles
          Settings.AutoConnect = false;
          General = {
            AddressRandomization = "network";
            AddressRandomizationRange = "full";
            # keep ip config in NetworkManager so ensureProfiles can set static addresses
            EnableNetworkConfiguration = false;
            RoamRetryInterval = 15;
          };
          Network = {
            EnableIPv6 = true;
            RoutePriorityOffset = 300;
          };
        };
      };

      systemd.network.enable = lib.mkForce false;
    };
}
