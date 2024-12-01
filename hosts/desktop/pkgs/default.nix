{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    toybox

    brave
    libarchive

    colmena
  ];
}
