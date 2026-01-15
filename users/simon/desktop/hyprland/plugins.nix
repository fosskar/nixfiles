{
  pkgs,
  ...
}:
{
  wayland.windowManager.hyprland = {
    #plugins = with inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}; [
    #  csgo-vulkan-fix
    #  #hyprscrolling
    #];

    plugins = [
      #pkgs.hyprlandPlugins.csgo-vulkan-fix
    ];

    #settings = {
    #  plugin = {
    #    csgo-vulkan-fix = {
    #      res_w = 1680;
    #      res_h = 1050;
    #      class = "cs2";
    #      #fix_mouse = true;
    #    };
    #    #hyprscrolling = {
    #    #  fullscreen_on_one_column = true;
    #    #};
    #  };
    #};
  };
}
