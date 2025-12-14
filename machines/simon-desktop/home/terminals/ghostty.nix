{ pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty;
    settings = {
      theme = "Brogrammer";
      font-family = "JetBrainsMono Nerd Font";
      font-size = 10; # default: 12
      background-opacity = 0.80; # default: 1.0
      background-blur = true; # default: false

      selection-foreground = "cell-background";
      selection-background = "cell-foreground";

      copy-on-select = false; # default: true
      confirm-close-surface = false; # default: true

      gtk-titlebar = false; # default: true
      gtk-toolbar-style = "flat"; # default: "raised"

      window-padding-x = 4; # default: 2
      window-padding-y = 4; # default: 2
      window-padding-balance = true; # default: false

      # keybind = [ ];  # add custom keybindings here if needed
    };
  };
}
