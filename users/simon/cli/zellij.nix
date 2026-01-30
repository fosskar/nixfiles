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
        bg = t.bg;
        fg = t.fg;
        red = t.error;
        green = t.term.green;
        blue = t.term.blue;
        yellow = t.warning;
        magenta = t.term.magenta;
        orange = t.warning;
        cyan = t.secondary;
        black = t.bg;
        white = t.fg;
      };
      pane_frames = false;
      default_layout = "compact";
      on_force_close = "quit";
    };
  };
}
