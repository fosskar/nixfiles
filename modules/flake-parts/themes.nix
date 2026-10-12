{
  # shared design tokens. pure metadata, like flake.domains; reachable in
  # home-manager modules via the self specialArg. palettes live under
  # self.themes.<name>; self.theme selects the active one, so consumers read
  # self.themes.${self.theme}.
  flake.theme = "pi-jade";

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

  # pi logo colours (pi.dev/press-kit) with a jade primary on pale pure greys
  flake.themes.pi-jade = {
    fonts = {
      sans = "Inter";
      mono = "CommitMono Nerd Font Propo";
    };

    dark = {
      bg = {
        base = "#262626";
        surface = "#2D2D2D";
        elevated = "#1F1F1F";
        overlay = "#343434";
      };
      fg = {
        base = "#C7C7C7";
        muted = "#9B9B9B";
        dim = "#6C6C6C";
        inverse = "#FFFFFF";
      };
      accent = {
        primary = "#6FC29B";
        secondary = "#F1BE58";
        tertiary = "#4D9ABF";
      };
      semantic = {
        success = "#6FC29B";
        error = "#F09082";
        warning = "#F1BE58";
        info = "#4D9ABF";
      };
    };

    # dark hues darkened to 4.5:1 on bg.base
    light = {
      bg = {
        base = "#EBEBEB";
        surface = "#E4E4E4";
        elevated = "#DCDCDC";
        overlay = "#D4D4D4";
      };
      fg = {
        base = "#222222";
        muted = "#5B5B5B";
        dim = "#8C8C8C";
        inverse = "#FFFFFF";
      };
      accent = {
        primary = "#1F7855";
        secondary = "#8A6403";
        tertiary = "#207296";
      };
      semantic = {
        success = "#1F7855";
        error = "#A85044";
        warning = "#8A6403";
        info = "#207296";
      };
      ansi = {
        normal = {
          black = "#EBEBEB";
          red = "#A85044";
          green = "#1F7855";
          yellow = "#8A6403";
          blue = "#207296";
          magenta = "#945680";
          cyan = "#017680";
          white = "#222222";
        };
        bright = {
          black = "#D4D4D4";
          red = "#A85044";
          green = "#1F7855";
          yellow = "#8A6403";
          blue = "#207296";
          magenta = "#945680";
          cyan = "#017680";
          white = "#1F1F1F";
        };
      };
    };

    ansi = {
      normal = {
        black = "#1F1F1F";
        red = "#F09082";
        green = "#6FC29B";
        yellow = "#F1BE58";
        blue = "#4D9ABF";
        magenta = "#D995C2";
        cyan = "#61BFC9";
        white = "#C7C7C7";
      };
      bright = {
        black = "#6C6C6C";
        red = "#F09082";
        green = "#6FC29B";
        yellow = "#F1BE58";
        blue = "#4D9ABF";
        magenta = "#D995C2";
        cyan = "#61BFC9";
        white = "#FFFFFF";
      };
    };
  };
}
