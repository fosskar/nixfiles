{ config, ... }:
{
  wayland.windowManager.hyprland = {
    settings = {
      bind =
        let
          binding =
            mod: cmd: key: arg:
            "${mod}, ${key}, ${cmd}, ${arg}";
          mvfocus = binding "SUPER" "movefocus";
          ws = binding "SUPER" "workspace";
          resizeactive = binding "SUPER CTRL" "resizeactive";
          mvactive = binding "SUPER ALT" "moveactive";
          mvtows = binding "SUPER SHIFT" "movetoworkspace";
          arr = [
            1
            2
            3
            4
            5
            6
            7
            8
            9
          ];
        in
        [
          # screenshots
          ", Print, exec, pgrep hyprshot || uwsm-app -- hyprshot -m region -o ~/pictures/screenshots -- imv"
          "CTRL, Print, exec, pgrep hyprshot || uwsm-app -- hyprshot -m output -o ~/pictures/screenshots -- imv"
          "SUPER, Print, exec, pgrep hyprshot || uwsm-app -- hyprshot -m window -o ~/pictures/screenshots -- imv"

          # gaming script
          "SUPER, Next, exec, ${config.xdg.configHome}/hypr/hypr-gamemode.sh"
          "SUPER, H, exec, ${config.xdg.configHome}/shortcut_info.sh"

          # start programs
          "SUPER, W, exec, uwsm app -- zen"
          "SUPER, T, exec, uwsm app -- ghostty"
          "SUPER, E, exec, uwsm app -- ghostty -e yazi"
          "SUPER, O, exec, uwsm app -- ts3client"
          "SUPER, Z, exec, uwsm app -- zeditor"
          "SUPER, D, exec, uwsm app -- webcord"

          # compositor commands
          "SUPER, G, togglegroup,"
          "SUPER, V, togglefloating,"
          "SUPER, F, fullscreen,"
          "SUPER, J, togglesplit,"
          "SUPER, P, pseudo,"
          "SUPER, L, exec, pgrep hyprlock || uwsm-app -- hyprlock"
          "SUPER, M, movetoworkspace, special"
          "SUPER SHIFT, E, exit,"
          "SUPER SHIFT, Q, killactive,"
          "ALT, Tab, focuscurrentorlast,"

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

          # global shortcuts/keybinds/hotkeys
          ",F9,pass,title:^(TeamSpeak 3)$"
          ",F10,pass,title:^(TeamSpeak 3)$"

          "SHIFT,Space,pass,^(awakened-poe-trade)$"
          "CTRL ALT,D,pass,^(awakened-poe-trade)$"
        ]
        ++ (map (i: ws (toString i) (toString i)) arr)
        ++ (map (i: mvtows (toString i) (toString i)) arr);

      # keyboard hotkeys
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

      bindr = [
        "SUPER, Space, exec, pkill anyrun || anyrun" # anyrun launcher
      ];
    };
  };
}
