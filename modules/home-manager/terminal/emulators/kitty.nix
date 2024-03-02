{...}: {
  programs.kitty = {
    enable = true;

    settings = {
      scrollback_lines = 10000;
      placement_strategy = "center";

      enable_audio_bell = "yes";
      visual_bell_duration = "0.1";

      copy_on_select = "clipboard";

      selection_foreground = "#171717";
      selection_background = "#00d787";

      # colors
      background = "#171717";
      foreground = "#eeeeee";

      cursor = "#d8caac";
    };
  };
}
