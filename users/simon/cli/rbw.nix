{ pkgs, ... }:
{
  home.packages = [
    pkgs.rbw
    pkgs.pinentry-gnome3
  ];
}
