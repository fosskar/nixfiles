{ pkgs, ... }:
{
  programs.kitty = {
    enable = true;
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

      # scrollback
      scrollback_lines = 10000;

      # mouse
      mouse_hide_wait = "0";
      url_style = "straight";
      copy_on_select = "clipboard";
      show_hyperlink_targets = "yes";
      underline_hyperlinks = "hover";
      strip_trailing_spaces = "smart";

      hide_window_decorations = "titlebar-only";

      # bell
      enable_audio_bell = "no";
      visual_bell_duration = "0";

      # layout
      remember_window_size = "no";
      placement_strategy = "center";
      confirm_os_window_close = "0";
      enabled_layouts = "Vertical, Splits, Horizontal, Grid, Fat, Stack, Tall";

      # tab bar
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      tab_bar_align = "left";
      tab_powerline_style = "round";
      #tab_bar_background = "#00d787";
      active_tab_foreground = "#171717";
      active_tab_background = "#00d787";
      active_tab_font_style = "bold-italic";
      inactive_tab_foreground = "#eeeeee";
      inactive_tab_background = "#171717";
      inactive_tab_font_style = "normal";

      disable_ligatures = "cursor";

      # color
      background = "#171717";
      foreground = "#eeeeee";
      selection_foreground = "#171717";
      selection_background = "#00d787";

      # cursor
      cursor = "#d8caac";
      cursor_shape = "beam";
      cursor_shape_unfocused = "block";
    };
  };
}
