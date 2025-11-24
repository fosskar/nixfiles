{ lib, ... }:
{
  networking = {
    useNetworkd = lib.mkDefault true;
    enableIPv6 = false;
  };

  systemd = {
    services = {
      NetworkManager-wait-online.enable = false;
      systemd-networkd.stopIfChanged = false;
      systemd-resolved.stopIfChanged = false;
    };
    network.wait-online.enable = false;
  };

  services.resolved.llmnr = lib.mkDefault "false";
}
