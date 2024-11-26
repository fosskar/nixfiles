{
  lib,
  config,
  inputs,
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
    ./shortcuts_info.nix
    ./plugins.nix
  ];

  options = {
    module.desktop.wayland.hyprland.enable = mkEnableOption "Enables hyprland";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      #xwaylandvideobridge #for screensharing xwayland application
      hyprshot # screenshot
      wl-clipboard # wayland clipboard
      hyprpicker # color picker
    ];

    home.sessionVariables = {
      QT_QPA_PLATFORM = "wayland";
      QT_AUTO_SCREEN_SCALE_FACTOR = 1;
      QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
      SDL_VIDEODRIVER = "wayland";
      GDK_BACKEND = "wayland";
      CLUTTER_BACKEND = "wayland";
    };

    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.default;
      systemd = {
        enable = false;
        variables = [ "--all" ];
        extraCommands = [
          "systemctl --user stop graphical-session.target"
          "systemctl --user start hyprland-session.target"
        ];
      };
    };
    systemd.user.targets.tray.Unit.Requires = lib.mkForce [ "graphical-session.target" ];
  };
}
