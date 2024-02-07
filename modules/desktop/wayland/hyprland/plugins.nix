{
  inputs,
  pkgs,
  ...
}: {
  wayland.windowManager.hyprland = {
    enable = true;
    plugins = [inputs.hyprland-plugins.packages.${pkgs.system}.csgo-vulkan-fix];
  };
}
