{ lib, ... }:
{
  # servers use pure systemd-networkd (no networkmanager)
  networking = {
    useNetworkd = lib.mkForce true;
    enableIPv6 = lib.mkForce false;
    dhcpcd.enable = false;
  };

  systemd = {
    network = {
      enable = lib.mkForce true;
      wait-online.enable = lib.mkDefault false;
    };
    services = {
      NetworkManager-wait-online.enable = lib.mkDefault false;
      systemd-networkd.stopIfChanged = lib.mkDefault false;
      systemd-resolved.stopIfChanged = lib.mkDefault false;
    };
  };
  services.resolved.llmnr = lib.mkDefault "false";
}
