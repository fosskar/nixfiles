{
  pkgs,
  ...
}:
{
  wayland.windowManager.hyprland = {
    plugins = with pkgs.hyprlandPlugins; [
      csgo-vulkan-fix
      #hyprscrolling
    ];

    settings = {
      plugin = {
        csgo-vulkan-fix = {
          res_w = 1680;
          res_h = 1050;
          class = "cs2";
          #fix_mouse = true;
        };
        #hyprscrolling = {
        #  fullscreen_on_one_column = true;
        #};
      };
    };
  };
}
