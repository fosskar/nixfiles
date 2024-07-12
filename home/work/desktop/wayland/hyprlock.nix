{ inputs, pkgs, ... }:
{
  programs.hyprlock = {
    enable = true;
    package = inputs.hyprlock.packages.${pkgs.system}.hyprlock;
    settings = {
      general = {
        disable_loading_bar = false;
        hide_cursor = true;
        grace = 3;
        no_fade_in = false;
        ignore_empty_input = false;
      };

      background = [
        {
          monitor = "";
          path = "";
          color = "rgba(20, 20, 20, 1)";

          blur_passes = 0;
          blur_size = 10;
          noise = 1.17e-2;
          contrast = 0.8916;
          brightness = 0.8172;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.0;
        }
      ];

      input-field = [
        {
          monitor = "DP-1";

          size = {
            width = 300;
            height = 50;
          };
          outline_thickness = 1;
          dots_size = 0.3;
          dots_spacing = 0.15;
          dots_center = true;
          outer_color = "rgba(20, 20, 20, 1)";
          inner_color = "rgba(51, 209, 122, 1)";
          font_color = "rgb(255, 255, 255)";
          fade_on_empty = false;
          placeholder_text = ''<span font_family="Inter">passwd</span>'';
          hide_input = false;
          halign = "center";
          valign = "center";
        }
      ];

      label = [
        {
          monitor = "";
          text = "<b>$TIME</b>";
          color = "rgb(255, 255, 255)";
          font_family = "Inter";
          font_size = 96;
          position = "0, 0";
          halign = "center";
          valign = "top";
        }
        {
          monitor = "";
          text = ''cmd[update:1000] echo "$(date "+%a %d %b")"'';
          color = "rgb(255, 255, 255)";
          font_family = "Inter";
          font_size = 24;
          position = "0, -150";
          halign = "center";
          valign = "top";
        }
        {
          monitor = "";
          text = "henlo <i>$USER</i>";
          color = "rgb(255, 255, 255)";
          font_family = "Inter";
          font_size = 32;
          position = "0, 200";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "";
          color = "rgb(255, 255, 255)";
          font_family = "Inter";
          font_size = 32;
          position = "0, 20";
          halign = "center";
          valign = "bottom";
        }
      ];
    };
  };
}
