{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.module.desktop.wayland.hyprland;
in

{
  imports = [
    ./binds.nix
    ./hyprmode.nix
    ./settings.nix
    ./rules.nix
    ./hyprlock.nix
    ./hypridle.nix
    ./plugins.nix
  ];

  options = {
    module.desktop.wayland.hyprland.enable = mkEnableOption "Enables hyprland";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      #xwaylandvideobridge # for screensharing xwayland application
      hyprshot # screenshot
      wl-clipboard # wayland clipboard
      hyprpicker # color picker
    ];

    home.sessionVariables = {
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_AUTO_SCREEN_SCALE_FACTOR = 1;
      QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
      #SDL_VIDEODRIVER = "wayland";
      GDK_BACKEND = "wayland,x11,*";
      CLUTTER_BACKEND = "wayland";
      OZONE_PLATFORM = "wayland";
      NIXOS_OZONE_WL = 1;
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "Hyprland";
      GTK_USE_PORTAL = "1";
    };

    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      portalPackage = null;
      systemd = {
        enable = false;
        variables = [ "--all" ];
        extraCommands = [
          "systemctl --user stop graphical-session.target"
          "systemctl --user start hyprland-session.target"
        ];
      };
    };
  };
}
