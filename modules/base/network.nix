{ lib, ... }:
{
  networking = {
    dhcpcd.enable = lib.mkDefault false;
    useNetworkd = true;
  };

  systemd = {
    network.wait-online.enable = lib.mkDefault false;
    services = {
      NetworkManager-wait-online.enable = lib.mkDefault false;
      systemd-networkd.stopIfChanged = lib.mkDefault false;
      systemd-resolved.stopIfChanged = lib.mkDefault false;
    };
  };

  services.resolved = {
    enable = lib.mkDefault true;
    # disable link-local multicast name resolution
    llmnr = lib.mkDefault "false";
  };
}
