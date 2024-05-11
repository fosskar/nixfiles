_: {
  wayland.windowManager.hyprland = {
    settings = {
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
        "minsize 1 1,title:^()$,class:^(steam)$"
        "suppressevent maximize,class:.*"
        "noinitialfocus,title:(^notificationtoasts.*)"
        "immediate, class:^(cs2)$"
        "immediate, class:^(gamescope|steam_app).*"
        "immediate, fullscreen:1"

        # make Firefox PiP window floating and sticky
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"
      ];
    };
  };
}
