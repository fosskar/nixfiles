_: {
  wayland.windowManager.hyprland = {
    settings = {
      exec-once = [
        "[workspace 3 silent] steam -console"
      ];
      env = [
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_QPA_PLATFORMTHEME,qt6ct"
        "GDK_BACKEND,wayland,x11,*"
        "CLUTTER_BACKEND,wayland"
        "OZONE_PLATFORM,wayland"
        "NIXOS_OZONE_WL,1"
        "XDG_CURRENT_DESKTOP = Hyprland"
        "XDG_SESSION_TYPE = wayland"
        "XDG_SESSION_DESKTOP = Hyprland"
        #"GTK_USE_PORTAL = 1"
        #"SDL_VIDEODRIVER,wayland"
      ];
      general = {
        #layout = "scrolling";
        border_size = 0;
        allow_tearing = true;
        gaps_in = 8;
        gaps_out = 16;
        "col.active_border" = "0xFF2BBF6E";
        "col.inactive_border" = "0xFF114D2C";
        resize_on_border = true;
      };
      decoration = {
        rounding = 12;
        rounding_power = 2.0;
        shadow = {
          enabled = true;
        };
        blur = {
          enabled = true;
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
        #sensitivity = 0;
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
        #background_color = "0x393939";
        vfr = true;
        vrr = 0;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        disable_autoreload = true;
        focus_on_activate = false;
        allow_session_lock_restore = 1;
      };
      xwayland = {
        use_nearest_neighbor = false;
        force_zero_scaling = true;
      };
      render = {
        direct_scanout = true;
      };
      debug = {
        disable_logs = true;
        error_position = 1;
        full_cm_proto = true;
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
