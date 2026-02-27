{
  config,
  inputs,
  pkgs,
  ...
}:
let
  dms-pkg = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
  dmsCall = "qs ipc --any-display -p ${dms-pkg}/share/quickshell/dms call";

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

  binding =
    mod: cmd: key: arg:
    "${mod}, ${key}, ${cmd}, ${arg}";

  ws = binding "SUPER" "workspace";
  mvtows = binding "SUPER CTRL" "movetoworkspace";
in
{
  wayland.windowManager.hyprland.settings = {
    bind = [
      # screenshots
      ", Print, exec, pgrep hyprshot || hyprshot -m region -o ~/pictures/screenshots -- imv"
      "CTRL, Print, exec, pgrep hyprshot || hyprshot -m output -o ~/pictures/screenshots -- imv"
      "SUPER, Print, exec, pgrep hyprshot || hyprshot -m window -o ~/pictures/screenshots -- imv"

      # gaming script
      "SUPER, Next, exec, ${config.xdg.configHome}/hypr/hypr-gamemode.sh"

      # program launches (aligned with niri)
      "SUPER, W, exec, zen"
      "SUPER, T, exec, ghostty"
      "SUPER, E, exec, ghostty -e yazi"
      "SUPER, Z, exec, zeditor"
      "SUPER, P, exec, ts3client"
      "SUPER, D, exec, webcord"

      # window management (aligned with niri)
      "SUPER, Q, killactive,"
      "SUPER, V, togglefloating,"
      "SUPER, F, fullscreen, 0"
      "SUPER SHIFT, F, fullscreen, 1"
      "SUPER SHIFT, E, exit,"
      "SUPER SHIFT, M, movetoworkspace, special"

      # focus movement (aligned with niri: Mod+arrows / Mod+hjkl)
      "SUPER, left, movefocus, l"
      "SUPER, down, movefocus, d"
      "SUPER, up, movefocus, u"
      "SUPER, right, movefocus, r"
      "SUPER, H, movefocus, l"
      "SUPER, J, movefocus, d"
      "SUPER, K, movefocus, u"
      "SUPER, L, movefocus, r"

      # move window (aligned with niri: Mod+Ctrl+arrows)
      "SUPER CTRL, left, movewindow, l"
      "SUPER CTRL, down, movewindow, d"
      "SUPER CTRL, up, movewindow, u"
      "SUPER CTRL, right, movewindow, r"
      "SUPER CTRL, H, movewindow, l"
      "SUPER CTRL, J, movewindow, d"
      "SUPER CTRL, K, movewindow, u"
      "SUPER CTRL, L, movewindow, r"

      # monitor focus (aligned with niri: Mod+Shift+Left/Right)
      "SUPER SHIFT, left, focusmonitor, l"
      "SUPER SHIFT, right, focusmonitor, r"

      # move to monitor (aligned with niri: Mod+Shift+Ctrl+arrows)
      "SUPER SHIFT CTRL, left, movecurrentworkspacetomonitor, l"
      "SUPER SHIFT CTRL, right, movecurrentworkspacetomonitor, r"
      "SUPER SHIFT CTRL, H, movecurrentworkspacetomonitor, l"
      "SUPER SHIFT CTRL, L, movecurrentworkspacetomonitor, r"

      # scrolling layout: column resize (aligned with niri: Mod+R / Mod+Minus/Plus)
      "SUPER, R, layoutmsg, colresize +conf"
      "SUPER SHIFT, R, layoutmsg, colresize -conf"
      "SUPER, minus, layoutmsg, colresize -0.1"
      "SUPER, plus, layoutmsg, colresize +0.1"

      # focus first/last column (aligned with niri: Mod+Home/End)
      "SUPER, Home, movefocus, l"
      "SUPER, End, movefocus, r"

      # scrolling layout: consume/expel (aligned with niri: Mod+BracketLeft/Right / Mod+Comma/Period)
      "SUPER, bracketleft, layoutmsg, absorb l"
      "SUPER, bracketright, layoutmsg, absorb r"
      "SUPER, comma, layoutmsg, absorb"
      "SUPER, period, layoutmsg, expel"

      # groups (keeping for non-scrolling compat)
      "SUPER, G, togglegroup,"

      # misc
      "ALT, Tab, focuscurrentorlast,"

      # dankmaterialshell (aligned with niri shell-binds.nix)
      "SUPER, B, exec, ${dmsCall} clipboard toggle"
      "SUPER, N, exec, ${dmsCall} notepad toggle"
      "SUPER SHIFT, L, exec, ${dmsCall} lock lock"
      "SUPER, X, exec, ${dmsCall} powermenu toggle"
      "SUPER, M, exec, ${dmsCall} processlist toggle"
      "SUPER, Tab, exec, ${dmsCall} hypr toggleOverview"

      # global shortcuts/keybinds/hotkeys
      ", F9, pass, class:^(TeamSpeak 3)$"
      ", F10, pass, class:^(TeamSpeak 3)$"
    ]
    ++ (map (i: ws (toString i) (toString i)) arr)
    ++ (map (i: mvtows (toString i) (toString i)) arr);

    # keyboard hotkeys
    bindle = [
      # dankmaterialshell audio/brightness (aligned with niri shell-binds.nix)
      ", XF86AudioRaiseVolume, exec, ${dmsCall} audio increment 5"
      ", XF86AudioLowerVolume, exec, ${dmsCall} audio decrement 5"
      ", XF86AudioMute, exec, ${dmsCall} audio mute"
      ", XF86AudioMicMute, exec, ${dmsCall} audio micmute"
      ", XF86MonBrightnessUp, exec, ${dmsCall} brightness increment 10 backlight:amdgpu_bl1"
      ", XF86MonBrightnessDown, exec, ${dmsCall} brightness decrement 10 backlight:amdgpu_bl1"

      ", XF86AudioPlay, exec, playerctl --player=spotify,firefox play-pause"
      ", XF86AudioPrev, exec, playerctl --player=spotify,firefox previous"
      ", XF86AudioNext, exec, playerctl --player=spotify,firefox next"
    ];

    bindr = [
      # launcher (aligned with niri: Mod+Space)
      "SUPER, Space, exec, ${dmsCall} spotlight toggle"
    ];

    bindm = [
      "SUPER, mouse:273, resizewindow"
      "SUPER, mouse:272, movewindow"
    ];
  };
}
