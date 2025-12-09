{ lib, ... }:
{
  # servers: no networkmanager, no ipv6
  networking.enableIPv6 = lib.mkForce false;
}
