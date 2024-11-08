{ lib, ... }:
{
  security = {
    sudo-rs.enable = lib.mkForce false;
  };
}
