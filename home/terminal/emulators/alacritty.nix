{pkgs, ...}: {
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        decorations = "none";
        dynamic_padding = true;
        padding = {
          x = 5;
          y = 5;
        };
        opacity = 1.0;
        startup_mode = "Windowed";
        title = "alacritty";
      };

      scrolling.history = 10000;

      font = {
        normal.family = "FiraCode Nerd Mono Font";
        bold.family = "FiraCode Nerd Mono Font Bold";
        italic.family = "FiraCode Nerd Mono Font Italic";
        size = 14;
      };
      colors = {
        primary = {
          background = "#2D353B";
          foreground = "#D3C6AA";
        };
        # Normal colors
        normal = {
          black = "#7A8478";
          red = "#E67E80";
          green = "#A7C080";
          yellow = "#DBBC7F";
          blue = "#7FBBB3";
          magenta = "#D699B6";
          cyan = "#83C092";
          white = "#D3C6AA";
        };
        # Bright colors
        bright = {
          black = "#859289";
          red = "#E67E80";
          green = "#A7C080";
          yellow = "#DBBC7F";
          blue = "#7FBBB3";
          magenta = "#D699B6";
          cyan = "#83C092";
          white = "#D3C6AA";
        };
      };
      cursor = {
        style = {
          # Values for `shape`:
          #   - ▇ Block
          #   - _ Underline
          #   - | Beam
          shape = "Block";
        };
      };
      draw_bold_text_with_bright_colors = true;
    };
  };
}
