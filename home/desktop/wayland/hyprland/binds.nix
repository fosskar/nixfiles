_: {
  wayland.windowManager.hyprland = {
    settings = {
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
          "ALT, Space,     ${e} -t launcher" # this is for AGS
          "SUPER, Tab,     ${e} -t overview"
          #"Print,         ${e} -r 'recorder.screenshot()'"
          #"SHIFT,Print,    ${e} -r 'recorder.screenshot(true)'"
          ",Print,exec,hyprshot -m region -o ~/Pictures/Screenshots -- imv"
          "CTRL,Print,exec,hyprshot -m output -o ~/Pictures/Screenshots -- imv"
          "SUPER,Print,exec,hyprshot -m window -o ~/Pictures/Screenshots -- imv"
          #"ALT, Space, exec, wofi --show drun" # when using waybar
          "SUPER, W, exec, firefox"
          "SUPER, T, exec, kitty"
          "SUPER, E, exec, kitty -e yazi"
          "ALT, Tab, focuscurrentorlast"
          "SUPER SHIFT, E, exit"
          "SUPER SHIFT, Q, killactive"
          "SUPER, V, togglefloating"
          "SUPER, F, fullscreen, 0"
          "SUPER, O, fakefullscreen"
          "SUPER, J, togglesplit"
          "SUPER, P, pseudo"
          "SUPER, C, exec, codium"
          "SUPER, Z, exec, zed"
          "SUPER, D, exec, webcord"
          "SUPER, L, exec, hyprlock"
          "SUPER, M, movetoworkspace, special"
          "SUPER, Next, exec, hyprctl keyword monitor 'DP-1,2560x1440@165,auto,1'; hyprctl --batch keyword 'animations:enabled 0'; corectrl -m 'gaming'; pkill ags"
          "SUPER, Prior, exec, hyprctl keyword monitor 'DP-1,3440x1440@165,auto,1'; hyprctl --batch 'keyword animations:enabled 1'; corectrl -m 'gaming'; hyprctl dispatch -- exec 'ags -b hypr' --single-instance"
          # global shortcuts/keybinds/hotkeys
          ",F9,pass,^(TeamSpeak 3)$"
          ",F10,pass,^(TeamSpeak 3)$"
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

      bindle = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1.0"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- --limit 0.0"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioPlay, exec, playerctl --player=spotify,firefox play-pause"
        ", XF86AudioPrev, exec, playerctl --player=spotify,firefox previous"
        ", XF86AudioNext, exec, playerctl --player=spotify,firefox next"
      ];

      bindm = [
        "SUPER, mouse:273, resizewindow"
        "SUPER, mouse:272, movewindow"
      ];
    };
  };
}
