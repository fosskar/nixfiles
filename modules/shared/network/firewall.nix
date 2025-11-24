{ lib, ... }:
{
  networking.firewall = {
    enable = true;
    allowPing = true;
    logRefusedConnections = lib.mkDefault false;
  };
}
