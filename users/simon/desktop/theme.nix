{ lib, ... }:
{
  options.theme = {
    # backgrounds
    bg = lib.mkOption {
      type = lib.types.str;
      default = "#181818";
    };
    bgLight = lib.mkOption {
      type = lib.types.str;
      default = "#1E1E1E";
    };
    bgLighter = lib.mkOption {
      type = lib.types.str;
      default = "#232323";
    };
    bgLightest = lib.mkOption {
      type = lib.types.str;
      default = "#282828";
    };

    # foregrounds
    fg = lib.mkOption {
      type = lib.types.str;
      default = "#CCCCCC";
    };
    fgMuted = lib.mkOption {
      type = lib.types.str;
      default = "#9D9D9D";
    };
    fgDim = lib.mkOption {
      type = lib.types.str;
      default = "#616161";
    };

    # accents
    primary = lib.mkOption {
      type = lib.types.str;
      default = "#16A085";
    };
    primaryDark = lib.mkOption {
      type = lib.types.str;
      default = "#0E6655";
    };
    secondary = lib.mkOption {
      type = lib.types.str;
      default = "#1ABC9C";
    };

    # semantic
    error = lib.mkOption {
      type = lib.types.str;
      default = "#F85149";
    };
    warning = lib.mkOption {
      type = lib.types.str;
      default = "#FFA000";
    };
    info = lib.mkOption {
      type = lib.types.str;
      default = "#1ABC9C";
    };

    # terminal palette (ANSI colors)
    term = {
      green = lib.mkOption {
        type = lib.types.str;
        default = "#73C991";
      };
      blue = lib.mkOption {
        type = lib.types.str;
        default = "#6796E6";
      };
      magenta = lib.mkOption {
        type = lib.types.str;
        default = "#C586C0";
      };
    };

    # light theme variants
    light = {
      bg = lib.mkOption {
        type = lib.types.str;
        default = "#FAFAFA";
      };
      bgDark = lib.mkOption {
        type = lib.types.str;
        default = "#F5F5F5";
      };
      bgDarker = lib.mkOption {
        type = lib.types.str;
        default = "#EEEEEE";
      };
      bgDarkest = lib.mkOption {
        type = lib.types.str;
        default = "#E0E0E0";
      };
      fg = lib.mkOption {
        type = lib.types.str;
        default = "#181818";
      };
      fgMuted = lib.mkOption {
        type = lib.types.str;
        default = "#616161";
      };
      outline = lib.mkOption {
        type = lib.types.str;
        default = "#B0BEC5";
      };
      primary = lib.mkOption {
        type = lib.types.str;
        default = "#0E6655";
      };
      primaryContainer = lib.mkOption {
        type = lib.types.str;
        default = "#A3E4D7";
      };
      error = lib.mkOption {
        type = lib.types.str;
        default = "#D32F2F";
      };
      warning = lib.mkOption {
        type = lib.types.str;
        default = "#F57C00";
      };
    };
  };
}
