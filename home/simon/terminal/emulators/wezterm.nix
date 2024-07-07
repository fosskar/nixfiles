{ ... }:
{
  programs.wezterm = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    colorSchemes = {
      "owntheme" = {
        ansi = [
          "#000000"
          "#ff5555"
          "#50fa7b"
          "#f1fa8c"
          "#bd93f9"
          "#ff79c6"
          "#8be9fd"
          "#bfbfbf"
        ];
        brights = [
          "#4d4d4d"
          "#ff6e67"
          "#5af78e"
          "#f4f99d"
          "#caa9fa"
          "#ff92d0"
          "#9aedfe"
          "#e6e6e6"
        ];
        foreground = "#eeeeee";
        background = "#171717";
        cursor_bg = "#d8caac";
        cursor_border = "#d8caac";
        cursor_fg = "#171717";
        selection_bg = "#00d787";
        selection_fg = "#171717";
      };
    };

    extraConfig = ''
      local wez = require 'wezterm'
      return {
        default_prog = { 'zsh' },
        cell_width = 0.85,
        enable_wayland = false,
        scrollback_lines = 10000,
        enable_scroll_bar = false,
        enable_kitty_keyboard = true,
        font = wezterm.font_with_fallback({
          "JetBrainsMono Nerd Font",
          "Material Design Icons",
          "Noto Color Emoji",
        }),
        dpi = 96.0,
        bold_brightens_ansi_colors = true,
        freetype_load_target = "Normal",
        font_size = 10.0,
        line_height = 1.0,
        harfbuzz_features = { 'cSHIFT=1', 'clig=1', 'liga=1' },
        color_scheme = "owntheme",
        window_padding = {
          left = "8pt", right = "8pt",
          bottom = "2pt", top = "2pt"
        },
        default_cursor_style = "SteadyUnderline",
        enable_scroll_bar = false,
        warn_about_missing_glyphs = false,
        enable_tab_bar = true,
        use_fancy_tab_bar = true,
        hide_tab_bar_if_only_one_tab = true,
        show_tab_index_in_tab_bar = false,
        window_frame = {
          font_size = 9.0,
          active_titlebar_bg = "#171717",
          inactive_titlebar_bg = "#171717",
        },
        colors = {
          tab_bar = {
            active_tab = {
              bg_color = '#00d787',
              fg_color = '#000000',
            },
            inactive_tab = {
              bg_color = '#171717',
              fg_color = '#ffffff',
            },
          },
        },
        window_close_confirmation = "NeverPrompt",
        inactive_pane_hsb = {
          saturation = 1.0, brightness = 0.8
        },
        front_end = "WebGpu",
        webgpu_power_preference = "LowPower",
        webgpu_force_fallback_adapter = true,
        check_for_updates = false,
        window_background_opacity = 1,
        adjust_window_size_when_changing_font_size = false,
        keys = {
          { key = "LeftArrow",   mods = "CTRL|SHIFT",   action = wezterm.action({ ActivatePaneDirection = "Left" }) },
          { key = "RightArrow",  mods = "CTRL|SHIFT",   action = wezterm.action({ ActivatePaneDirection = "Right" }) },
          { key = "DownArrow",   mods = "CTRL|SHIFT",   action = wezterm.action({ ActivatePaneDirection = "Down" }) },
          { key = "UpArrow",     mods = "CTRL|SHIFT",   action = wezterm.action({ ActivatePaneDirection = "Up" }) },

          { key = "Enter",       mods = "CTRL|SHIFT",   action = wezterm.action({ SplitVertical   = { domain = "CurrentPaneDomain" }, }) },
          { key = "h",           mods = "CTRL|SHIFT",   action = wezterm.action({ SplitHorizontal = { domain = "CurrentPaneDomain" }, }) },
          { key = "q",           mods = "CTRL|SHIFT",   action = wezterm.action({ CloseCurrentPane = { confirm = false } }) },

          { key = "1",           mods = "CTRL|SHIFT",   action = wezterm.action({ ActivateTab = 0 }) },
          { key = "2",           mods = "CTRL|SHIFT",   action = wezterm.action({ ActivateTab = 1 }) },
          { key = "3",           mods = "CTRL|SHIFT",   action = wezterm.action({ ActivateTab = 2 }) },
          { key = "4",           mods = "CTRL|SHIFT",   action = wezterm.action({ ActivateTab = 3 }) },
          { key = "5",           mods = "CTRL|SHIFT",   action = wezterm.action({ ActivateTab = 4 }) },
          { key = "6",           mods = "CTRL|SHIFT",   action = wezterm.action({ ActivateTab = 5 }) },
          { key = "7",           mods = "CTRL|SHIFT",   action = wezterm.action({ ActivateTab = 6 }) },
          { key = "8",           mods = "CTRL|SHIFT",   action = wezterm.action({ ActivateTab = 7 }) },
          { key = "9",           mods = "CTRL|SHIFT",   action = wezterm.action({ ActivateTab = -1 }) },
        },
      }
    '';
  };
}
