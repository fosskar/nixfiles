_: {
  flake.modules.homeManager.zellij =
    { config, ... }:
    let
      t = config.theme;
    in
    {
      programs.zellij = {
        enable = true;
        settings = {
          theme = "custom";
          themes.custom = {
            bg = t.dark.bg.base;
            fg = t.dark.fg.base;
            red = t.dark.semantic.error;
            green = t.ansi.normal.green;
            blue = t.ansi.normal.blue;
            yellow = t.dark.semantic.warning;
            magenta = t.ansi.normal.magenta;
            orange = t.dark.semantic.warning;
            cyan = t.ansi.normal.cyan;
            black = t.dark.bg.base;
            white = t.dark.fg.base;
          };
          pane_frames = false;
          default_layout = "compact";
          on_force_close = "quit";
        };
      };
    };
}
