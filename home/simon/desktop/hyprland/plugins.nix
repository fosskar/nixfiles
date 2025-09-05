{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
{
  wayland.windowManager.hyprland = {
    plugins = with inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}; [
      csgo-vulkan-fix
    ];

    settings = {
      plugin = {
        csgo-vulkan-fix = {
          res_w = 1680;
          res_h = 1050;
          class = "cs2";
          #fix_mouse = true;
        };
      };
    };
  };
}
