{ config, ... }:
{
  wayland.windowManager.hyprland = {
    settings = {
      exec-once = [
        "ags -b hypr"
        "steam -silent"
        "udiskie &"
        "hyprctl setcursor ${config.home.pointerCursor.name} ${toString config.home.pointerCursor.size}"
        "hyprlock"
      ];
      env = [
        #"WLR_DRM_NO_ATOMIC,1"
        "GDK_BACKEND,wayland,x11,*"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "CLUTTER_BACKEND,wayland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "OZONE_PLATFORM,wayland"
        #"NIXOS_OZONE_WL,1"
        #"SDL_VIDEODRIVER,wayland"
        "HYPRCURSOR_THEME,${config.home.pointerCursor.name}"
        "HYPRCURSOR_SIZE,${toString config.home.pointerCursor.size}"

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
        drop_shadow = false;
        blur = {
          enabled = false;
        };
      };

      animations = {
        enabled = true;
      };

      input = {
        kb_layout = "de";
        sensitivity = 1;
        accel_profile = "flat";
        follow_mouse = 2;
        float_switch_override_focus = 1;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
        vfr = true;
        vrr = 0;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        disable_autoreload = true;
        focus_on_activate = true;
        no_direct_scanout = false;
      };

      xwayland = {
        use_nearest_neighbor = false;
        force_zero_scaling = true;
      };

      debug = {
        disable_logs = true;
        error_position = 1;
      };

      monitor = [ "DP-1,3440x1440@165,auto,1" ];

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };
    };
  };
}
