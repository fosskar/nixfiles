{ lib, ... }:
{
  security = {
    sudo-rs = {
      enable = lib.mkForce true;
      wheelNeedsPassword = lib.mkForce false;
      execWheelOnly = lib.mkForce true;
    };

    sudo = {
      enable = lib.mkForce false;
    };
  };
}
