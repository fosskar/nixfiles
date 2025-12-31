{
  config,
  pkgs,
  mylib,
  ...
}:
{
  imports = mylib.scanPaths ./. { };

  home = {
    pointerCursor = {
      package = pkgs.capitaine-cursors;
      name = "capitaine-cursors";
      # available sizes for capitaine-cursors are:
      # 24, 30, 36, 48, 60, 72
      size = 24;
      gtk.enable = true;
      x11.enable = true;
      sway.enable = true;
    };
    sessionVariables = {
      GTK_THEME = config.gtk.theme.name;
      XCURSOR_SIZE = config.home.pointerCursor.size;
      XCURSOR_THEME = config.home.pointerCursor.name;
      # Scaling variables for proper DPI handling
      #GDK_SCALE = "1";
      #QT_SCALE_FACTOR = "1";
      #QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      #QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    };
  };
}
