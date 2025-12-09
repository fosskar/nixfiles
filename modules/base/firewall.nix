{ lib, ... }:
{
  networking = {
    firewall = {
      enable = true;
      allowPing = lib.mkDefault true;
      logRefusedConnections = lib.mkDefault false;
    };
    nftables.enable = lib.mkDefault true;
  };
}
