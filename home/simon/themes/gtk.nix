{
  lib,
  pkgs,
  config,
  ...
}:

with lib;

let
  cfg = config.module.themes.gtk;
in
{
  options.module.themes.gtk = {
    enable = mkEnableOption "Enable gtk";
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      GTK_THEME = config.gtk.theme.name;
    };

    gtk = {
      enable = true;
      font = {
        name = "Inter";
        package = pkgs.inter;
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
        gtk-application-prefer-dark-theme = true;

        # Decorations
        gtk-decoration-layout = "appmenu:none";
        gtk-toolbar-style = "GTK_TOOLBAR_BOTH";
        gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
        gtk-button-images = 1;
        gtk-menu-images = 1;

        # Silence bells and whistles, quite literally.
        gtk-error-bell = 0;
        gtk-enable-event-sounds = 0;
        gtk-enable-input-feedback-sounds = 0;

        # Fonts
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintslight";
        gtk-xft-rgba = "rgb";
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;

        # Decorations.
        gtk-decoration-layout = "appmenu:none";

        # Sounds, again.
        gtk-error-bell = 0;
        gtk-enable-event-sounds = 0;
        gtk-enable-input-feedback-sounds = 0;

        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintslight";
        gtk-xft-rgba = "rgb";

      };
    };
    xdg.configFile =
      let
        gtk4Dir = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0";
      in
      {
        "gtk-4.0/assets".source = "${gtk4Dir}/assets";
        "gtk-4.0/gtk.css".source = "${gtk4Dir}/gtk.css";
        "gtk-4.0/gtk-dark.css".source = "${gtk4Dir}/gtk-dark.css";
      };
  };
}
