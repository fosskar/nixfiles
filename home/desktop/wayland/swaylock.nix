{
  config,
  default,
  pkgs,
  ...
}: {
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      color = "#1E1E1E";
      line-uses-ring = false;
      grace = 2;
      grace-no-mouse = true;
      grace-no-touch = true;
      fade-in = "0.1";
      show-failed-attempts = false;
      daemonize = true;
      screenshots = false;
      clock = true;
      datestr = "";
      timestr = "";
      text-ver = "󱥸";
      text-wrong = "";
      text-clear = "󱞱";
      indicator = true;
      indicator-idle-visible = true;
      ignore-empty-password = true;
      disable-caps-lock-text = true;
      font = "FiraCode Nerd Font";
      font-size = 200;
      effect-blur = "12x3";
      indicator-radius = 210;
      indicator-thickness = 10;
      line-color = "26252788";
      line-clear-color = "26252788";
      line-ver-color = "26252788";
      line-wrong-color = "26252788";
      inside-color = "26252788";
      inside-clear-color = "26252788";
      inside-ver-color = "26252788";
      inside-wrong-color = "26252788";
      text-color = "F7F1FF";
      text-clear-color = "F7F1FF";
      text-ver-color = "F7F1FF";
      text-wrong-color = "F7F1FF";
      ring-color = "5AD4E6";
      ring-clear-color = "5AD4E6";
      ring-ver-color = "5AD4E6";
      bs-hl-color = "FC618D";
      ring-wrong-color = "FC618D";
      key-hl-color = "948AE3";
      separator-color = "403e42";
    };
  };
}
