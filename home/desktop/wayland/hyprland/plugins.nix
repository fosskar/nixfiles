{
  inputs,
  pkgs,
  ...
}: {
  wayland.windowManager.hyprland = {
    enable = true;
    plugins = [inputs.hyprland-plugins.packages.${pkgs.system}.csgo-vulkan-fix];
    extraConfig = ''
      plugin {
        csgo-vulkan-fix {
          res_w = 1920
          res_h = 1080
          class = cs2
        }
      }
    '';
  };
}
