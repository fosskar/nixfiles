{ pkgs, config, ... }:
let
  t = config.theme;
in
{
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty;
    themes.grey-teal = {
      background = t.bg;
      foreground = t.fg;
      cursor-color = t.primary;
      selection-background = t.primary;
      selection-foreground = "#FFFFFF";
      palette = [
        "0=${t.bg}"
        "1=${t.error}"
        "2=${t.term.green}"
        "3=${t.warning}"
        "4=${t.term.blue}"
        "5=${t.term.magenta}"
        "6=${t.secondary}"
        "7=${t.fg}"
        "8=${t.fgDim}"
        "9=${t.error}"
        "10=${t.term.green}"
        "11=${t.warning}"
        "12=${t.term.blue}"
        "13=${t.term.magenta}"
        "14=${t.secondary}"
        "15=#FFFFFF"
      ];
    };
    settings = {
      theme = "grey-teal";
      font-family = config.monospaceFont;
      font-size = 10;
      copy-on-select = false;
      window-padding-x = 4;
      window-padding-y = 4;
      window-padding-balance = true;
    };
  };
}
