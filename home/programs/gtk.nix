{
  pkgs,
  config,
  ...
}: {
  home = {
    pointerCursor = {
      package = pkgs.capitaine-cursors;
      name = "capitaine-cursors";
      # available sizes for capitaine-cursors are:
      # 24, 30, 36, 48, 60, 72
      size = 24;
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
      package = pkgs.inter;
    };
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3.overrideAttrs (_self: _super: {
        postInstall = ''
          rm -rf $out/share/themes/adw-gtk3/gtk-4.0
          rm -rf $out/share/themes/adw-gtk3-dark/gtk-4.0
        '';
      });
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
