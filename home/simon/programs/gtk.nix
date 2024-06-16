{ pkgs, config, ... }:
{
  home = {
    pointerCursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      # available sizes for are:
      # 16 20 22 24 28 32 40 48 56 64 72 80 88 96
      size = 20;
      gtk.enable = true;
      x11.enable = true;
    };
    sessionVariables = {
      GTK_THEME = config.gtk.theme.name;
      XCURSOR_SIZE = config.home.pointerCursor.size;
      XCURSOR_THEME = config.home.pointerCursor.name;
    };
  };

  gtk = {
    enable = true;
    font = {
      name = "Inter";
      package = pkgs.google-fonts.override { fonts = [ "Inter" ]; };
    };
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    cursorTheme = {
      inherit (config.home.pointerCursor) name;
      inherit (config.home.pointerCursor) package;
      inherit (config.home.pointerCursor) size;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk2 = {
      configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
      extraConfig = ''
        gtk-xft-antialias=1
        gtk-xft-hinting=1
        gtk-xft-hintstyle="hintfull"
        gtk-xft-rgba="rgb"
      '';
    };
    gtk3.extraConfig = {
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
      gtk-application-prefer-dark-theme = 1;
    };
  };
}
