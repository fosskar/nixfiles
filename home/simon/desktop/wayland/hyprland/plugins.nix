{ inputs, pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    plugins = with inputs.hyprland-plugins.packages.${pkgs.system}; [
      csgo-vulkan-fix
      #hy3
      #hyprbars
      #hyprexpo
    ];

    settings = {
      plugin = {
        csgo-vulkan-fix = {
          res_w = 1440;
          res_h = 1080;
          class = "cs2";
          #fix_mouse = true;
        };

        hyprbars = {
          bar_height = 25;
          bar_precedence_over_border = false;
          bar_part_of_window = true;

          # r to l
          hyprbars-button = [
            "rgb(ff4040), 14, 󰖭, hyprctl dispatch killactive"
            "rgb(eeee11), 14, , hyprctl dispatch fullscreen 1"
          ];
        };
        hyprexpo = {
          columns = 3;
          gap_size = 4;
          bg_col = "rgb(000000)";
        };
      };
    };
  };
}
