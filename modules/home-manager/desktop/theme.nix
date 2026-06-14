_: {
  flake.modules.homeManager.theme =
    { lib, ... }:
    let
      strOption =
        default:
        lib.mkOption {
          type = lib.types.str;
          inherit default;
        };
    in
    {
      options.theme = {
        fonts = {
          sans = strOption "Inter";
          mono = strOption "CommitMono Nerd Font Propo";
        };

        dark = {
          bg = {
            base = strOption "#202020";
            surface = strOption "#282828";
            elevated = strOption "#181818";
            overlay = strOption "#303030";
          };

          fg = {
            base = strOption "#CCCCCC";
            muted = strOption "#9D9D9D";
            dim = strOption "#616161";
            inverse = strOption "#FFFFFF";
          };

          accent = {
            primary = strOption "#16A085";
            secondary = strOption "#C79A3A";
            tertiary = strOption "#6796E6";
          };

          semantic = {
            success = strOption "#73C991";
            error = strOption "#F07167";
            warning = strOption "#C79A3A";
            info = strOption "#6796E6";
          };
        };

        light = {
          bg = {
            base = strOption "#FAFAFA";
            surface = strOption "#F2F2F2";
            elevated = strOption "#EAEAEA";
            overlay = strOption "#E0E0E0";
          };

          fg = {
            base = strOption "#181818";
            muted = strOption "#616161";
            dim = strOption "#9D9D9D";
            inverse = strOption "#FFFFFF";
          };

          accent = {
            primary = strOption "#16A085";
            secondary = strOption "#C79A3A";
            tertiary = strOption "#6796E6";
          };

          semantic = {
            success = strOption "#73C991";
            error = strOption "#F07167";
            warning = strOption "#C79A3A";
            info = strOption "#6796E6";
          };
        };

        ansi = {
          normal = {
            black = strOption "#181818";
            red = strOption "#F07167";
            green = strOption "#73C991";
            yellow = strOption "#C79A3A";
            blue = strOption "#6796E6";
            magenta = strOption "#C586C0";
            cyan = strOption "#1ABC9C";
            white = strOption "#CCCCCC";
          };

          bright = {
            black = strOption "#616161";
            red = strOption "#F07167";
            green = strOption "#73C991";
            yellow = strOption "#C79A3A";
            blue = strOption "#6796E6";
            magenta = strOption "#C586C0";
            cyan = strOption "#1ABC9C";
            white = strOption "#FFFFFF";
          };
        };
      };
    };
}
