{ pkgs, ... }:
{
  networking = {
    hostName = "simon-laptop";
    useNetworkd = true;
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      wifi = {
        #backend = "iwd";
        powersave = true;
        macAddress = "random"; # use a random mac address on every boot
        scanRandMacAddress = true; # MAC address randomization of a Wi-Fi device during scanning
      };
      plugins = with pkgs; [
        networkmanager-openconnect
        networkmanager-openvpn
        networkmanager-sstp
      ];
    };
    nameservers = [
      # mullevad svenska also best
      "194.242.2.2"
      "2a07:e340::2"

      # dns.sb germany
      "45.11.45.11"
      "185.222.222.222"
      "2a11::"
      "2a09::"

      # quad9, schwiz. at leats not usa
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
    };
  };
}
