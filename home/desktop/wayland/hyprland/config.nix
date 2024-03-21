{
  config,
  default,
  pkgs,
  ...
}: {
  wayland.windowManager.hyprland = {
    systemd.enable = true;
    xwayland.enable = true;

    settings = {
      exec-once = [
        "ags -b hypr"
        #"waybar"
        "easyeffects --gapplication-service"
        "steam -silent"
        "corectrl"
        "udiskie &" # automatically mount usb
        #"solaar --window=hide"
        "hyprctl setcursor capitaine-cursors 24"
      ];

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
      };

      input = {
        kb_layout = "de";
        follow_mouse = 2;
        accel_profile = "flat";
        sensitivity = 0;
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
          #new_optimizations = "on";
          #size = 3;
          #passes = 1;
        };
        drop_shadow = false;
        #shadow_range = 4;
        #shadow_render_power = 3;
      };

      animations = {
        enabled = "yes";
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      dwindle = {
        pseudotile = "yes";
        preserve_split = "yes";
      };

      master = {
        new_is_master = true;
      };

      gestures = {
        workspace_swipe = "off";
      };

      xwayland = {
        force_zero_scaling = true;
        use_nearest_neighbor = false;
      };

      windowrule = let
        f = regex: "float, .*(${regex}).*";
      in [
        (f "steam")
        (f "WebCord")
        (f "pavucontrol")
        (f "com.github.Aylur.ags")
        (f "bitwarden")
        (f "TeamSpeak")
        (f "btop")
        (f "Picture-in-Picture")
        "workspace 2 silent,^(WebCord)$"
        "workspace 2 silent,^(Steam)|(steam)$"
      ];
      windowrulev2 = [
        #"stayfocused,title:^()$,class:^(steam)$"
        #"minsize 1 1,title:^()$,class:^(steam)$"
        "suppressevent maximize,class:.*"
        "noinitialfocus,title:(^notificationtoasts.*)"
        "immediate, class:^(cs2)$"
        "immediate, class:^(gamescope|steam_app).*"
        "immediate, fullscreen:1"

        # make Firefox PiP window floating and sticky
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"
      ];

      bind = let
        binding = mod: cmd: key: arg: "${mod}, ${key}, ${cmd}, ${arg}";
        mvfocus = binding "SUPER" "movefocus";
        ws = binding "SUPER" "workspace";
        resizeactive = binding "SUPER CTRL" "resizeactive";
        mvactive = binding "SUPER ALT" "moveactive";
        mvtows = binding "SUPER SHIFT" "movetoworkspace";
        e = "exec, ags -b hypr";
        arr = [1 2 3 4 5 6 7 8 9];
      in
        [
          "ALT, Space,     ${e} -t applauncher" # this is for AGS
          "SUPER, Tab,     ${e} -t overview"
          #"Print,         ${e} -r 'recorder.screenshot()'"
          #"SHIFT,Print,    ${e} -r 'recorder.screenshot(true)'"
          ",Print,exec,hyprshot -m region -o ~/Pictures/Screenshots -- imv"
          "CTRL,Print,exec,hyprshot -m output -o ~/Pictures/Screenshots -- imv"
          "SUPER,Print,exec,hyprshot -m window -o ~/Pictures/Screenshots -- imv"
          #"ALT, Space, exec, wofi --show drun" # when using waybar
          "SUPER, W, exec, firefox"
          "SUPER, T, exec, kitty"
          "SUPER, E, exec, thunar"
          "ALT, Tab, focuscurrentorlast"
          "SUPER SHIFT, E, exit"
          "SUPER SHIFT, Q, killactive"
          "SUPER, V, togglefloating"
          "SUPER, F, fullscreen, 0"
          "SUPER, O, fakefullscreen"
          "SUPER, J, togglesplit"
          "SUPER, P, pseudo"
          "SUPER, C, exec, codium"
          "SUPER, D, exec, webcord"
          "SUPER, L, exec, hyprlock"
          "SUPER, M, movetoworkspace, special"
          "SUPER, Next, exec, hyprctl keyword monitor 'DP-1,2560x1440@165,auto,1'; hyprctl --batch keyword 'animations:enabled 0'; corectrl -m 'gaming'; pkill ags"
          "SUPER, Prior, exec, hyprctl keyword monitor 'DP-1,3440x1440@165,auto,1'; hyprctl --batch 'keyword animations:enabled 1'; corectrl -m 'gaming'; ags -b hypr & disown"

          (mvfocus "up" "u")
          (mvfocus "down" "d")
          (mvfocus "right" "r")
          (mvfocus "left" "l")
          (ws "left" "e-1")
          (ws "right" "e+1")
          (mvtows "left" "e-1")
          (mvtows "right" "e+1")
          (resizeactive "up" "0 -20")
          (resizeactive "down" "0 20")
          (resizeactive "right" "20 0")
          (resizeactive "left" "-20 0")
          (mvactive "up" "0 -20")
          (mvactive "down" "0 20")
          (mvactive "right" "20 0")
          (mvactive "left" "-20 0")
        ]
        ++ (map (i: ws (toString i) (toString i)) arr)
        ++ (map (i: mvtows (toString i) (toString i)) arr);

      bindle = let
        e = "exec, ags -b hypr -r";
      in [
        ",XF86AudioRaiseVolume,  ${e} 'audio.speaker.volume += 0.05; indicator.speaker()'"
        ",XF86AudioLowerVolume,  ${e} 'audio.speaker.volume -= 0.05; indicator.speaker()'"
        ",XF86AudioMute,  ${e} 'audio.speaker.volume = 0; indicator.speaker(); audio.speaker.volume = 1; indicator.speaker()'"
      ];

      bindm = [
        "SUPER, mouse:273, resizewindow"
        "SUPER, mouse:272, movewindow"
      ];
    };
    extraConfig = ''
      env = WLR_DRM_NO_ATOMIC,1
      env = GDK_BACKEND,wayland,x11
      env = QT_QPA_PLATFORM,wayland;xcb
      env = QT_AUTO_SCREEN_SCALE_FACTOR,1
      env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
      env = CLUTTER_BACKEND,wayland
      env = XDG_CURRENT_DESKTOP,Hyprland
      env = XDG_SESSION_TYPE,wayland
      env = XDG_SESSION_DESKTOP,Hyprland
      env = OZONE_PLATFORM,wayland
    '';
  };
}
