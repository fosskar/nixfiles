{ lib, ... }:
{
  security = {
    sudo-rs.enable = lib.mkForce false;
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
      execWheelOnly = true;
    };
  };
}
