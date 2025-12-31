_: {
  programs.zathura = {
    enable = true;
    options = {
      # unified dark theme matching hyprland/hyprpanel
      recolor = true;
      recolor-lightcolor = "#171717";
      recolor-darkcolor = "#eeeeee";
      default-bg = "#171717";
      default-fg = "#eeeeee";
      statusbar-bg = "#171717";
      statusbar-fg = "#eeeeee";
      inputbar-bg = "#1e1e1e";
      inputbar-fg = "#eeeeee";
      completion-bg = "#171717";
      completion-fg = "#eeeeee";
      completion-highlight-bg = "#a3a3a3";
      completion-highlight-fg = "#171717";
      highlight-color = "#a3a3a3";
      highlight-active-color = "#a3a3a3";

      font = "Inter 12";
      selection-notification = true;

      selection-clipboard = "clipboard";
      adjust-open = "best-fit";
      pages-per-row = "1";
      scroll-page-aware = "true";
      scroll-full-overlap = "0.01";
      scroll-step = "100";
      smooth-scroll = true;
      zoom-min = "10";
    };
  };
}
