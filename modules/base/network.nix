{ lib, ... }:
{
  # common network settings for all machines
  networking.dhcpcd.enable = lib.mkDefault false;

  systemd = {
    network.wait-online.enable = lib.mkDefault false;
    services = {
      NetworkManager-wait-online.enable = lib.mkDefault false;
      systemd-networkd.stopIfChanged = lib.mkDefault false;
      systemd-resolved.stopIfChanged = lib.mkDefault false;
    };
  };

  services.resolved.llmnr = lib.mkDefault "false";
}
