{config, ...}: {
  wayland.windowManager.hyprland = {
    settings = {
      exec-once = [
        "ags -b hypr"
        #"waybar"
        "steam -silent"
        "corectrl"
        "udiskie &"
        "hyprctl setcursor ${config.home.pointerCursor.name} ${toString config.home.pointerCursor.size}"
        "hypridle"
        "hyprlock"
      ];
      env = [
        "WLR_DRM_NO_ATOMIC,1"
        "GDK_BACKEND,wayland,x11,*"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "CLUTTER_BACKEND,wayland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "OZONE_PLATFORM,wayland"
        "SDL_VIDEODRIVER,wayland"
      ];

      debug = {
        disable_logs = true;
      };

      monitor = [
        "DP-1,3440x1440@165,auto,1"
      ];

      misc = {
        disable_splash_rendering = true;
        disable_hyprland_logo = true;
        force_default_wallpaper = 0;
        vfr = true;
        vrr = 0;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        no_direct_scanout = false;
        disable_autoreload = true;
        focus_on_activate = true;
      };

      input = {
        kb_layout = "de";
        follow_mouse = 2;
        float_switch_override_focus = 1;
        accel_profile = "flat";
        force_no_accel = false;
        sensitivity = 1;
      };

      general = {
        allow_tearing = true;
        gaps_in = 4;
        gaps_out = 6;
        border_size = 1;
        layout = "dwindle";
        resize_on_border = true;
        "col.active_border" = "rgba(00D787ff)";
        "col.inactive_border" = "rgba(333333ff)";
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled = false;
          #new_optimizations = true;
          #size = 3;
          #passes = 1;
        };
        drop_shadow = false;
        #shadow_range = 4;
        #shadow_render_power = 3;
      };

      animations = {
        enabled = true;
      };

      dwindle = {
        pseudotile = false;
        preserve_split = true;
      };

      master = {
        new_is_master = true;
      };

      gestures = {
        workspace_swipe = false;
      };

      xwayland = {
        force_zero_scaling = true;
        use_nearest_neighbor = false;
      };
    };
  };
}
