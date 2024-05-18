_: {
  wayland.windowManager.hyprland = {
    settings = {
      windowrulev2 = [
        # webcord
        "float, initialclass:^(WebCord)$"
        "workspace 2, initialclass:^(WebCord)$"
        "size 450 600, initialclass:^(WebCord)$"
        "center, initialclass:^(WebCord)$"

        # steam
        "float, title:^(Steam)$"
        "workspace 2, title:^(Steam)$"
        "size 450 600, title:^(Steam)$"

        "float, title:^(Steam)$"
        "size 1000 300, title:^(Friends List)$"
        "workspace 2, title:^(Steam)$"

        "size 800 800, title:^(Steam Settings)$"
        "workspace 2, title:^(Steam)$"

        # ts3
        "float, title:^(TeamSpeak 3)$"
        "workspace 2, title:^(TeamSpeak 3)$"
        "size 450 600, title:^(TeamSpeak 3)$"

        # suppress notification events when gaming
        "idleinhibit fullscreen, class:.*"
        "suppressevent maximize,class:.*"
        "noinitialfocus,title:(^notificationtoasts.*)"

        # immediate
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
