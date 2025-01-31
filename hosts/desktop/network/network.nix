{ lib, ... }:
{
  networking = {
    hostName = "nixos";
    useNetworkd = true;
    useDHCP = lib.mkDefault true;
    networkmanager = {
      enable = true;
      wifi = {
        #backend = "iwd";
        macAddress = "random";
        powersave = true;
        scanRandMacAddress = true;
      };
      dns = "systemd-resolved";
    };

    nameservers = [
      # mullevad also best
      "194.242.2.2"
      "2a07:e340::2"

      # quad9, said to be the best
      # shares *less* data
      "9.9.9.9"
      "149.112.112.112"
      "2620:fe::fe"
      "2620:fe::9"
    ];
  };
  # prevent nm-wait-online timeout after nm upgrades
  systemd = {
    network.wait-online.enable = false;
    services = {
      systemd-networkd.stopIfChanged = false;
      systemd-resolved.stopIfChanged = false;
      NetworkManager-wait-online.enable = false;
      #NetworkManager-wait-online.serviceConfig.ExecStart = [
      #  ""
      #  "${pkgs.networkmanager}/bin/nm-online -q"
      #];
    };
  };
}
