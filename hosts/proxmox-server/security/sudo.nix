{ lib, ... }:
{
  security = {
    sudo-rs.enable = lib.mkForce false;
    sudo = {
      wheelNeedsPassword = false;
      extraConfig = ''
        Defaults lecture = never
      '';
    };
  };
}
