{
  flake.modules.nixos.workstation =
    { lib, config, ... }:
    {
      # add wheel users to networkmanager group
      users.groups.networkmanager.members = config.users.groups.wheel.members;

      # wireless regulatory database
      hardware.wirelessRegulatoryDatabase = true;

      # persist networkmanager + iwd state
      preservation.preserveAt."/persist".directories = [
        "/var/lib/NetworkManager"
        "/var/lib/iwd"
      ];

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
          # let networkmanager drive autoconnect; iwd-only autoconnect races
          # with nm-ensure-profiles and synthesizes a dhcp profile for known
          # ssids before the declarative profile activates.
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
