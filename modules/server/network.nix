{ lib, ... }:
{
  # servers use pure systemd-networkd (no networkmanager)
  networking = {
    useNetworkd = lib.mkForce true;
    enableIPv6 = lib.mkForce false;
  };

  systemd.network.enable = lib.mkForce true;
}
