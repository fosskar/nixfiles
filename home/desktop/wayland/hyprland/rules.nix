_: {
  wayland.windowManager.hyprland = {
    settings = {
      windowrulev2 = [
        # webcord
        "workspace 2, class:^(WebCord)$"

        # steam
        "workspace 2, class:^(steam)$"

        # ts3
        "workspace 2, title:^(TeamSpeak 3)$"

        # suppress notification events when gaming
        "suppressevent maximize,class:.*"
        "noinitialfocus, title:^(notificationtoasts.*)$, floating:1"

        # idle inhibit on any class that is fullscreen
        "idleinhibit fullscreen, class:.*"

        # immediate
        "immediate, class:^(cs2)$"
        "immediate, class:^(gamescope|steam_app).*"
        "immediate, fullscreen:1"

        # make Firefox PiP window floating and sticky
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"

        # dim around specific applications
        "dimaround, class:^(xdg-desktop-portal-gtk)$"
        "dimaround, class:^(polkit-gnome-authentication-agent-1)$"
      ];
    };
  };
}
