{ lib, ... }:
{
  networking = {
    useNetworkd = lib.mkForce true;
    enableIPv6 = lib.mkForce false;
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
