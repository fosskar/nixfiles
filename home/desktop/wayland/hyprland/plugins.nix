{
  inputs,
  pkgs,
  ...
}: {
  wayland.windowManager.hyprland = {
    plugins = with inputs.hyprland-plugins.packages.${pkgs.system}; [
      csgo-vulkan-fix
      #hy3
      #hyprbars
    ];

    settings = {
      plugin = {
        csgo-vulkan-fix = {
          res_w = 1280;
          res_h = 960;
          class = "cs2";
        };
      };
    };
  };
}
