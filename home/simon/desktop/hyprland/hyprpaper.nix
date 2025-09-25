{
  pkgs,
  inputs,
  lib,
  ...
}:
let
  wallpaper1 = "${inputs.wallpaper}/a_forest_with_moss_and_trees.jpg";
  wallpaper2 = "${inputs.wallpaper}/astronaut-high.jpg";
in
{
  services.hyprpaper = {
    enable = true;
    package = pkgs.hyprpaper;

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
  systemd.user.services = {
    hyprpaper = {
      Unit = {
        ConditionEnvironment = lib.mkForce [
          "WAYLAND_DISPLAY"
          "XDG_CURRENT_DESKTOP=Hyprland"
        ];
      };
    };
  };
}
