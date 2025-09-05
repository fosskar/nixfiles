{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  wallpaper1 = "${inputs.wallpaper}/a_forest_with_moss_and_trees.jpg";
  wallpaper2 = "${inputs.wallpaper}/astronaut-high.jpg";
in
{
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
}
