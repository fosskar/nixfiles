{
  pkgs,
  ...
}:
{
  programs.hyprlock = {
    enable = true;
    package = pkgs.hyprlock;
    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = true;
        immediate_render = true;
        ignore_empty_input = true;
        fail_timeout = 1000;
      };
      animation = [
        "inputFieldDots, 1, 2, linear"
        "fadeIn, 0"
      ];
      background = [
        {
          monitor = "";
          path = "";
          color = "rgba(12,12,12,0.8)"; # #333333 matte black old: "rgba(20, 20, 20, 1)"

          blur_passes = 4;
          blur_size = 7;
        }
      ];

      input-field = [
        {
          monitor = "";

          size = "300, 60";
          outline_thickness = 1;
          dots_size = 0.3;
          dots_spacing = 0.1;
          dots_center = true;
          dots_rounding = "-2";
          outer_color = "rgba(20, 20, 20, 1)";
          inner_color = "rgba(51, 209, 122, 1)";
          font_color = "rgb(255, 255, 255)";
          font_family = "Inter";
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
          font_size = 94;
          position = "0, -80";
          halign = "center";
          valign = "top";
        }
        {
          monitor = "";
          text = ''cmd[update:1000] echo "$(date "+%a %d %b")"'';
          color = "rgb(255, 255, 255)";
          font_family = "Inter";
          font_size = 24;
          position = "0, -210";
          halign = "center";
          valign = "top";
        }
        {
          monitor = "";
          text = "henlo <i>$USER</i>";
          color = "rgb(255, 255, 255)";
          font_family = "Inter";
          font_size = 32;
          position = "0, 240";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
