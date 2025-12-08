{ lib, ... }:
{
  networking = {
    firewall = {
      enable = lib.mkDefault true;
      allowPing = lib.mkDefault true;
      logRefusedConnections = lib.mkDefault false;
    };
    nftables.enable = lib.mkDefault true;
  };
}
