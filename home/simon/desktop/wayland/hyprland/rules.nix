_: {
  wayland.windowManager.hyprland = {
    settings = {
      windowrulev2 = [
        # webcord
        "workspace 2 silent, class:^(WebCord)$"

        # steam
        "workspace 2 silent, class:^(steam)$"

        # ts3
        "workspace 2 silent, title:^(TeamSpeak 3)$"

        # suppress notification events when gaming
        "suppressevent maximize, class:.*"
        "suppressevent maximize fullscreen, class:^(cs2)$"
        "noinitialfocus, class:^(steam)$, title:^(notificationtoasts.*)$, floating:1"

        # idle inhibit on any class that is fullscreen
        "idleinhibit fullscreen, class:.*"

        # immediate
        #"immediate, fullscreen:1" # immediate for all fullscreen applcations
        "immediate, class:^(cs2)$"
        "immediate, class:^(deadlock)$"
        "immediate, class:^(gamescope)$" # Apply fullscreen to gamescope
        "immediate, class:^(steam_app_.*),title:(.*)" # Apply fullscreen to Steam games

        # make Firefox PiP window floating and sticky
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"

        # dim around specific applications
        "dimaround, class:^(xdg-desktop-portal-gtk)$"
        "dimaround, class:^(polkit-pantheon-authentication-agent-1)$"
      ];
    };
  };
}
