_: {
  programs.zellij = {
    enable = true;
    enableFishIntegration = false;
    enableZshIntegration = false;
    themes = {
      default = ''
        themes {
          default {
            fg 238 238 238
            bg 23 23 23
            black 23 23 23
            red 237 51 59
            green 80 250 123
            yellow 241 250 140
            blue 189 147 249
            magenta 255 121 198
            cyan 139 233 253
            white 238 238 238
            orange 255 135 0
          }
        }
      '';
    };
  };
}
