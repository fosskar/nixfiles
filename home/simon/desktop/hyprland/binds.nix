{ config, ... }:
{
  wayland.windowManager.hyprland = {
    settings =
      let
        dmsCall = "qs ipc -c dms --any-display call";
      in
      {
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
            ", Print, exec, pgrep hyprshot || hyprshot -m region -o ~/pictures/screenshots -- imv"
            "CTRL, Print, exec, pgrep hyprshot || hyprshot -m output -o ~/pictures/screenshots -- imv"
            "SUPER, Print, exec, pgrep hyprshot || hyprshot -m window -o ~/pictures/screenshots -- imv"

            # gaming script
            "SUPER, Next, exec, ${config.xdg.configHome}/hypr/hypr-gamemode.sh"

            ## defaults
            # start programs
            "SUPER, W, exec, zen"
            "SUPER, T, exec, ghostty"
            "SUPER, E, exec, ghostty -e yazi"
            "SUPER, O, exec, ts3client"
            "SUPER, Z, exec, zeditor"
            "SUPER, D, exec, webcord"

            "SUPER, G, togglegroup,"
            "SUPER, V, togglefloating,"
            "SUPER, F, fullscreen,"
            "SUPER, J, togglesplit,"
            "SUPER, P, pseudo,"
            #"SUPER, L, exec, loginctl lock-session"
            "SUPER, M, movetoworkspace, special"
            "SUPER SHIFT, E, exit,"
            "SUPER SHIFT, Q, killactive,"
            "ALT, Tab, focuscurrentorlast,"

            # dankmaterialshell
            "SUPER, C, exec, ${dmsCall} clipboard toggle"
            "SUPER, N, exec, ${dmsCall} notepad toggle"
            "SUPER, L, exec, ${dmsCall} lock lock"
            "SUPER, X, exec, ${dmsCall} powermenu toggle"
            "SUPER SHIFT, Space, exec, ${dmsCall} control-center toggle"
            "SUPER, Tab, exec, ${dmsCall} hypr toggleOverview"

            "SUPER, Tab, exec, ${dmsCall} hypr toggleOverview"
            "SUPER, Tab, exec, ${dmsCall} hypr toggleOverview"
            "SUPER, Tab, exec, ${dmsCall} hypr toggleOverview"

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
            ", F9, pass, class:^(TeamSpeak 3)$"
            ", F10, pass, class:^(TeamSpeak 3)$"
          ]
          ++ (map (i: ws (toString i) (toString i)) arr)
          ++ (map (i: mvtows (toString i) (toString i)) arr);

        # keyboard hotkeys
        bindle = [

          ## defaults
          #", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1.0"
          #", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- --limit 0.0"
          #", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"

          # dankmaterialshell
          ", XF86AudioRaiseVolume, exec,${dmsCall} audio increment 5"
          ", XF86AudioLowerVolume, exec, ${dmsCall} audio decrement 5"
          ", XF86AudioMute, exec, ${dmsCall} audio mute"
          ", XF86AudioMicMute, exec, ${dmsCall} audio micmute"
          ", XF86MonBrightnessUp, exec, ${dmsCall} brightness increment 5 ''"
          ", XF86MonBrightnessDown, exec, ${dmsCall} brightness decrement 5 ''"

          ", XF86AudioPlay, exec, playerctl --player=spotify,firefox play-pause"
          ", XF86AudioPrev, exec, playerctl --player=spotify,firefox previous"
          ", XF86AudioNext, exec, playerctl --player=spotify,firefox next"
        ];
        bindr = [
          ## launcher
          #"SUPER, Space, exec, pkill anyrun || anyrun" # anyrun launcher
          #"SUPER, Space, exec, pkill sherlock || sherlock"
          "SUPER, Space, exec, ${dmsCall} spotlight toggle"
        ];

        bindm = [
          "SUPER, mouse:273, resizewindow"
          "SUPER, mouse:272, movewindow"
        ];
      };
  };
}
