{ lib, ... }:
let
  color =
    default:
    lib.mkOption {
      type = lib.types.str;
      inherit default;
    };
in
{
  options.theme = {
    # fonts
    font = color "Inter";
    monospaceFont = color "CommitMono Nerd Font Propo";

    # backgrounds
    bg = color "#181818";
    bgLight = color "#1E1E1E";
    bgLighter = color "#232323";
    bgLightest = color "#282828";

    # foregrounds
    fg = color "#CCCCCC";
    fgMuted = color "#9D9D9D";
    fgDim = color "#616161";

    # accents
    primary = color "#16A085";
    primaryDark = color "#0E6655";
    secondary = color "#1ABC9C";

    # semantic
    error = color "#F85149";
    warning = color "#FFA000";
    info = color "#1ABC9C";

    # terminal palette (ANSI colors)
    term = {
      green = color "#73C991";
      blue = color "#6796E6";
      magenta = color "#C586C0";
    };

    # light theme variants
    light = {
      bg = color "#FAFAFA";
      bgDark = color "#F5F5F5";
      bgDarker = color "#EEEEEE";
      bgDarkest = color "#E0E0E0";
      fg = color "#181818";
      fgMuted = color "#616161";
      outline = color "#B0BEC5";
      primary = color "#0E6655";
      primaryContainer = color "#A3E4D7";
      error = color "#D32F2F";
      warning = color "#F57C00";
    };
  };
}
