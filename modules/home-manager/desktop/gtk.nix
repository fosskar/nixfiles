_: {
  flake.modules.homeManager.gtk =
    {
      self,
      pkgs,
      config,
      ...
    }:
    let
      settings = {
        gtk-decoration-layout = "appmenu:none";
        gtk-error-bell = 0;
      };
    in
    {
      gtk = {
        enable = true;
        font.name = self.themes.${self.theme}.fonts.sans;
        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };
        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
        colorScheme = "dark";
        gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
        gtk3.extraConfig = settings;
        gtk4 = {
          theme = config.gtk.theme;
          extraConfig = settings;
        };
      };
    };
}
