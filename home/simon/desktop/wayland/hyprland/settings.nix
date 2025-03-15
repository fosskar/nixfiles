_: {
  wayland.windowManager.hyprland = {
    settings = {
      exec-once = [
        # uwsm finalize startup
        "uwsm finalize"
        "uwsm app -- hyprlock"
        "uwsm app -- hyprpanel"
        "[workspace 3 silent] steam -console"
      ];
      env = [
        #"SDL_VIDEODRIVER,wayland"
      ];
      general = {
        border_size = 1;
        allow_tearing = true;
        gaps_in = 4;
        gaps_out = 6;
        "col.active_border" = "rgba(00D787ff)";
        "col.inactive_border" = "rgba(333333ff)";
        resize_on_border = true;
      };
      decoration = {
        rounding = 8;
        rounding_power = 3;
        shadow = {
          enabled = false;
        };
        blur = {
          enabled = false;
        };
      };
      animations = {
        enabled = true;
      };
      input = {
        kb_layout = "de";
        kb_model = "pc105";
        kb_variant = "";
        kb_options = "";
        sensitivity = 0;
        accel_profile = "flat";
        #force_no_accel = true;
        follow_mouse = 2;
        float_switch_override_focus = 1;
      };
      misc = {
        font_family = "Inter";
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
        vfr = true;
        vrr = 0;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        disable_autoreload = true;
        focus_on_activate = false;
      };
      xwayland = {
        use_nearest_neighbor = false;
        force_zero_scaling = true;
      };
      render = {
        direct_scanout = 1;
        explicit_sync = 1;
        explicit_sync_kms = 1;
      };
      debug = {
        disable_logs = true;
        error_position = 1;
      };
      monitor = [
        "DP-1, 3440x1440@164.9, 0x0, 1"
        "HDMI-A-2, 1920x1080@239.76, auto-right, 1, transform, 3"
      ];
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };
      cursor = {
        no_hardware_cursors = false;
      };
      ecosystem = {
        no_donation_nag = true;
      };
      #experimental = {
      #  wide_color_gamut = true;
      #};
    };
  };
}
