{...}: {
  programs.foot = {
    enable = true;

    settings = {
      main = {
        font = "${default.terminal.font}:size=${toString default.terminal.size}";
        box-drawings-uses-font-glyphs = "yes";
        pad = "0x0 center";
        notify = "notify-send -a \${app-id} -i \${app-id} \${title} \${body}";
        selection-target = "clipboard";
      };

      scrollback = {
        lines = 10000;
        multiplier = 3;
      };

      cursor = {
        style = "beam";
        beam-thickness = 1;
      };
    };
  };
}
