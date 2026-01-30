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
        inherit (t) bg;
        inherit (t) fg;
        red = t.error;
        inherit (t.term) green;
        inherit (t.term) blue;
        yellow = t.warning;
        inherit (t.term) magenta;
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
