{ pkgs, ... }:
{
  programs.kitty = {
    enable = true;
    shellIntegration = {
      enableZshIntegration = true;
      enableBashIntegration = true;
    };
    font = {
      size = 10;
      name = "JetBrainsMono Nerd Font";
    };

    keybindings = {
      #"ctrl+shift+m" = "toggle_maximized";
      #"ctrl+shift+f" = "show_scrollback"; # search in the current window
    };

    settings = {
      shell = "${pkgs.zsh}/bin/zsh";
      term = "xterm-256color";

      confirm_os_window_close = "0";
      scrollback_lines = 10000;
      show_hyperlink_targets = "yes";
      underline_hyperlinks = "never";
      disable_ligatures = "cursor";
      placement_strategy = "center";

      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";

      enable_audio_bell = "yes";
      visual_bell_duration = "0.05";

      copy_on_select = "clipboard";

      selection_foreground = "#171717";
      selection_background = "#00d787";

      # colors
      background = "#171717";
      foreground = "#eeeeee";

      cursor = "#d8caac";
    };
  };
  pam.sessionVariables = {
    KITTY_DISABLE_WAYLAND = 1;
    LANGUAGE = "en";
    LANG = "en_US.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_ADDRESS = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_IDENTIFICATION = "e_DE.UTF-8";
    PAPERSIZE = "a4";
  };
}
