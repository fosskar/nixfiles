{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
with lib;

let
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
          "/home/simon/pictures/wallpapers/a_mountain_with_snow_and_clouds.jpg"
          "/home/simon/pictures/wallpapers/a_drawing_of_an_astronaut_in_space.png"
          "/home/simon/pictures/wallpapers/a_snowy_mountain_tops.jpg"
          "/home/simon/pictures/wallpapers/an_astronaut_in_space_with_a_glowing_planet.png"
        ];

        wallpaper = [
          "DP-1,/home/simon/pictures/wallpapers/an_astronaut_in_space_with_a_glowing_planet.png"
          "HDMI-A-2,/home/simon/pictures/wallpapers/a_drawing_of_an_astronaut_in_space.png"
        ];
      };
    };
  };
}
