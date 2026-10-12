{
  # shared design tokens. pure metadata, like flake.domains; reachable in
  # home-manager modules via the self specialArg. palettes live under
  # self.themes.<name>; self.theme selects the active one, so consumers read
  # self.themes.${self.theme}.
  flake.theme = "grey-teal";

  flake.themes.grey-teal = {
    fonts = {
      sans = "Inter";
      mono = "CommitMono Nerd Font Propo";
    };

    dark = {
      bg = {
        base = "#202020";
        surface = "#282828";
        elevated = "#181818";
        overlay = "#303030";
      };
      fg = {
        base = "#CCCCCC";
        muted = "#9D9D9D";
        dim = "#616161";
        inverse = "#FFFFFF";
      };
      accent = {
        primary = "#16A085";
        secondary = "#B68601";
        tertiary = "#5A8EE5";
      };
      semantic = {
        success = "#43A66A";
        error = "#E65B53";
        warning = "#B68601";
        info = "#5A8EE5";
      };
    };

    # dark hues darkened to 4.5:1 on bg.base
    light = {
      bg = {
        base = "#FAFAFA";
        surface = "#F2F2F2";
        elevated = "#EAEAEA";
        overlay = "#E0E0E0";
      };
      fg = {
        base = "#181818";
        muted = "#616161";
        dim = "#9D9D9D";
        inverse = "#FFFFFF";
      };
      accent = {
        primary = "#00836C";
        secondary = "#956D00";
        tertiary = "#4072C7";
      };
      semantic = {
        success = "#16844B";
        error = "#CD433E";
        warning = "#956D00";
        info = "#4072C7";
      };
      ansi = {
        normal = {
          black = "#FAFAFA";
          red = "#CD433E";
          green = "#16844B";
          yellow = "#956D00";
          blue = "#4072C7";
          magenta = "#9F5C9A";
          cyan = "#06836C";
          white = "#181818";
        };
        bright = {
          black = "#E0E0E0";
          red = "#CD433E";
          green = "#16844B";
          yellow = "#956D00";
          blue = "#4072C7";
          magenta = "#9F5C9A";
          cyan = "#06836C";
          white = "#181818";
        };
      };
    };

    ansi = {
      normal = {
        black = "#181818";
        red = "#E65B53";
        green = "#43A66A";
        yellow = "#B68601";
        blue = "#5A8EE5";
        magenta = "#B773B2";
        cyan = "#09A78A";
        white = "#CCCCCC";
      };
      bright = {
        black = "#616161";
        red = "#E65B53";
        green = "#43A66A";
        yellow = "#B68601";
        blue = "#5A8EE5";
        magenta = "#B773B2";
        cyan = "#09A78A";
        white = "#FFFFFF";
      };
    };
  };

}
