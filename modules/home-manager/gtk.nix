{
  pkgs,
  config,
  ...
}: {
  #home.pointerCursor = {
  #  #package = pkgs.capitaine-cursors;
  #  #name = "capitaine-cursors";
  #  #size = 28;
  #  gtk.enable = true;
  #  x11.enable = true;
  #};

  gtk = {
    enable = true;
    #font = {
    #  name = "Roboto Regular";
    #  package = pkgs.roboto;
    #};
    #theme = {
    #  name = "adw-gtk3-dark";
    #  package = pkgs.adw-gtk3;
    #};
    #cursorTheme = {
    #  name = "capitaine-cursors";
    #  package = pkgs.capitaine-cursors;
    #  size = 26;
    #};

    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";

    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig = {
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
      gtk-application-prefer-dark-theme = 1;
    };
    gtk2.extraConfig = ''
      gtk-xft-antialias=1
      gtk-xft-hinting=1
      gtk-xft-hintstyle="hintslight"
      gtk-xft-rgba="rgb"
    '';

    gtk4.extraConfig = {gtk-application-prefer-dark-theme = 1;};
  };

  qt = {
    enable = true;
    platformTheme = "gtk3";
    style.name = "adwaita-dark";
  };
}
