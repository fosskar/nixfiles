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
        secondary = "#C79A3A";
        tertiary = "#6796E6";
      };
      semantic = {
        success = "#73C991";
        error = "#F07167";
        warning = "#C79A3A";
        info = "#6796E6";
      };
    };

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
        primary = "#16A085";
        secondary = "#C79A3A";
        tertiary = "#6796E6";
      };
      semantic = {
        success = "#73C991";
        error = "#F07167";
        warning = "#C79A3A";
        info = "#6796E6";
      };
    };

    ansi = {
      normal = {
        black = "#181818";
        red = "#F07167";
        green = "#73C991";
        yellow = "#C79A3A";
        blue = "#6796E6";
        magenta = "#C586C0";
        cyan = "#1ABC9C";
        white = "#CCCCCC";
      };
      bright = {
        black = "#616161";
        red = "#F07167";
        green = "#73C991";
        yellow = "#C79A3A";
        blue = "#6796E6";
        magenta = "#C586C0";
        cyan = "#1ABC9C";
        white = "#FFFFFF";
      };
    };
  };
}
