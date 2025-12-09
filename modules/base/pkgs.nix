{ lib, pkgs, ... }:
{
  environment = {
    defaultPackages = lib.mkForce [ ]; # no extra default packages are installed
    systemPackages = with pkgs; [
      curl
      gitMinimal
    ];
  };
}
