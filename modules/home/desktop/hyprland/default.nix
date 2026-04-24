{
  flake.modules.homeManager.hyprland = {
    home.packages = [
      #hyprshot # screenshot
      #wl-clipboard # wayland clipboard
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      #package = null;
      #portalPackage = null;
      systemd = {
        enable = true;
        variables = [ "--all" ];
      };
    };
  };
}
