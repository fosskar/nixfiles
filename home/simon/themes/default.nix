{ pkgs, ... }:
{
  imports = [
    ./gtk.nix
    ./qt.nix
  ];

  home = {
    pointerCursor = {
      name = "phinger-cursors-light"; # alt: Bibata-Modern-Classic
      package = pkgs.phinger-cursors; # alt: bibata-cursors
      # available sizes for are:
      # 16 20 22 24 28 32 40 48 56 64 72 80 88 96
      size = 20;
      gtk.enable = true;
      x11.enable = false;
      hyprcursor = {
        enable = true;
        size = 20;
      };
    };
  };
}
