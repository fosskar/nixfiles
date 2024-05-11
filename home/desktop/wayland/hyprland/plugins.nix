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
          res_w = 1920;
          res_h = 1080;
          class = "cs2";
        };
      };
    };
  };
}
