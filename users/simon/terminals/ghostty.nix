{ pkgs, config, ... }:
let
  t = config.theme;
in
{
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty;

    installBatSyntax = true;
    installVimSyntax = true;

    enableBashIntegration = true;
    enableFishIntegration = true;
    enableZshIntegration = true;

    themes.grey-teal = {
      background = t.dark.bg.base;
      foreground = t.dark.fg.base;
      cursor-color = t.dark.accent.primary;
      selection-background = t.dark.accent.primary;
      selection-foreground = "#FFFFFF";
      palette = [
        "0=${t.dark.bg.base}"
        "1=${t.dark.semantic.error}"
        "2=${t.ansi.normal.green}"
        "3=${t.dark.semantic.warning}"
        "4=${t.ansi.normal.blue}"
        "5=${t.ansi.normal.magenta}"
        "6=${t.ansi.normal.cyan}"
        "7=${t.dark.fg.base}"
        "8=${t.dark.fg.dim}"
        "9=${t.dark.semantic.error}"
        "10=${t.ansi.normal.green}"
        "11=${t.dark.semantic.warning}"
        "12=${t.ansi.normal.blue}"
        "13=${t.ansi.normal.magenta}"
        "14=${t.ansi.normal.cyan}"
        "15=#FFFFFF"
      ];
    };
    settings = {
      theme = "grey-teal";
      font-family = config.theme.fonts.mono;
      font-size = 10;
      copy-on-select = false;
      window-padding-x = 4;
      window-padding-y = 4;
      window-padding-balance = true;
      clipboard-trim-trailing-spaces = true;
      focus-follows-mouse = true;
    };
  };
}
