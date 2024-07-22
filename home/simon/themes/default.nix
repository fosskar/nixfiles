{ config, pkgs, ... }:
{
  imports = [
    ./gtk.nix
    ./qt.nix
  ];

  home = {
    pointerCursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      # available sizes for are:
      # 16 20 22 24 28 32 40 48 56 64 72 80 88 96
      size = 20;
      gtk.enable = true;
      x11.enable = false;
    };
    sessionVariables = {
      GTK_THEME = config.gtk.theme.name;
      # i use hyprcursor
      #XCURSOR_SIZE = config.home.pointerCursor.size;
      #XCURSOR_THEME = config.home.pointerCursor.name;
    };
  };
}
