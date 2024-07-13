{ lib, pkgs, ... }:
{

  environment = {
    defaultPackages = lib.mkForce [ ]; # remove default packages
    systemPackages = with pkgs; [
      zoom-us
      glxinfo
      lshw
      sbctl
    ];
  };
}
