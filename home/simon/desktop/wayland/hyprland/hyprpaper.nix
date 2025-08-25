{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
with lib;

let
  wallpaper1 = "${inputs.wallpaper}/astronaut-high.jpg";
  wallpaper2 = "${inputs.wallpaper}/astronaut-high.jpg";

  cfg = config.module.desktop.wayland.hyprland.hyprpaper;
in
{
  options = {
    module.desktop.wayland.hyprland.hyprpaper.enable = mkEnableOption "Enables hyprpaper";
  };

  config = mkIf cfg.enable {
    services.hyprpaper = {
      enable = true;
      package = inputs.hyprpaper.packages.${pkgs.system}.default;

      settings = {
        #ipc = "on";
        #splash = false;
        #splash_offset = 2.0;

        preload = [
          wallpaper1
          wallpaper2
        ];

        wallpaper = [
          "DP-1,${wallpaper1}"
          "HDMI-A-2,${wallpaper2}"
        ];
      };
    };
  };
}
