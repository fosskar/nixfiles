{
  inputs,
  pkgs,
  ...
}: {
  wayland.windowManager.hyprland = {
    enable = true;
    plugins = [inputs.hyprland-plugins.packages.${pkgs.system}.csgo-vulkan-fix];
    settings = {
      "plugin:csgo-vulkan-fix" = {
        res_w = 1440;
        res_h = 1080;
        class = "cs2";
      };
    };
  };
}
