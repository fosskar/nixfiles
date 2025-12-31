_: {
  services.dunst = {
    enable = true;
    settings = {
      global = {
        font = "Inter 10";
        monitor = 0;
        follow = "mouse";
        indicate_hidden = "yes";
        stack_duplicates = true;
        hide_duplicate_count = false;

        title = "Dunst";
        class = "Dunst";

        show_age_threshold = 60;
        ellipsize = "middle";
        ignore_newline = "no";
        show_indicators = "no";
        sticky_history = "no";
        history_length = 20;

        always_run_script = true;
        ignore_dbusclose = false;
        force_xinerama = false;

        # Notification
        sort = "yes";
        scale = 0;
        shrink = "no";
        word_wrap = "yes";

        # Geometry
        width = "0,400";
        height = "0,400";
        origin = "top-right";
        #offset = "12+24";

        padding = 8;
        horizontal_padding = 8;
        notification_limit = 0;
        separator_height = 2;

        # Progress-Bar
        progress_bar = true;
        progress_bar_height = 10;
        progress_bar_frame_width = 1;
        progress_bar_min_width = 150;
        progress_bar_max_width = 300;

        frame_width = 1;
        separator_color = "frame";
        transparency = 0;

        idle_threshold = 120;
        markup = "full";
        alignment = "left";
        vertical_alignment = "center";

        icon_position = "left";
        icon_theme = "Papirus";
        min_icon_size = 0;
        max_icon_size = 32;

        # Keybindings
        close = "ctrl+space";
        close_all = "ctrl+shift+space";
        history = "ctrl+grave";
        context = "ctrl+shift+period";

        mouse_left_click = "close_current";
        mouse_middle_click = "do_action, close_current";
        mouse_right_click = "close_all";
      };

      experimental = {
        per_monitor_dpi = true;
      };
      fullscreen_pushback_everything = {
        fullscreen = "pushback";
      };
      global = {
        highlight = "#78A1BB";
        foreground = "#EBF5EE";
        background = "#212121";
        frame_color = "#78A1BB";
      };
    };
  };
}
