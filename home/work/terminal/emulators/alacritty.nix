_: {
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        decorations = "Full";
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
        normal.family = "JetBrainsMono Nerd Font";
        bold.family = "JetBrainsMono Nerd Font";
        italic.family = "JetBrainsMono Nerd Font";
        size = 9;
      };
      colors = {
        draw_bold_text_with_bright_colors = true;
        primary = {
          background = "#171717";
          foreground = "#eeeeee";
        };
        normal = {
          black = "#10100E";
          red = "#C40233";
          green = "#009F6B";
          yellow = "#FFD700";
          blue = "#0087BD";
          magenta = "#9A4EAE";
          cyan = "#20B2AA";
          white = "#edecee";
        };
        bright = {
          black = "#4d4d4d";
          red = "#FF2400";
          green = "#03C03C";
          yellow = "#ffca85";
          blue = "#007FFF";
          magenta = "#FF1493";
          cyan = "#00CCCC";
          white = "#FDFF00";
        };
        selection = {
          text = "CellForeground";
          background = "#29263c";
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
    };
  };
}
