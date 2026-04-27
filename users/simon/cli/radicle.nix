{ pkgs, ... }:
{
  home.packages = with pkgs; [
    radicle-node
    radicle-desktop
  ];
}
