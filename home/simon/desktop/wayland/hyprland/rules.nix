_: {
  wayland.windowManager.hyprland = {
    settings = {
      windowrulev2 = [
        # webcord
        "workspace 9 silent, class:^(WebCord)$"

        # steam
        "workspace 9 silent, class:^(steam)$"

        # ts3
        "workspace 9 silent, title:^(TeamSpeak 3)$"

        # suppress notification events when gaming
        "suppressevent maximize, class:.*"
        "suppressevent maximize fullscreen, class:^(cs2)$"
        "noinitialfocus, class:^(steam)$, title:^(.*)$"
        "noinitialfocus, class:^(steam)$, title:^(notificationtoasts.*)$, floating:1"

        # idle inhibit on any fullscreen app
        "idleinhibit fullscreen, class:^(.*)$"
        "idleinhibit fullscreen, title:^(.*)$"
        "idleinhibit fullscreen, fullscreen:1"

        # immediate
        #"immediate, fullscreen:1" # immediate for all fullscreen applcations
        "immediate, class:^(cs2)$"
        "immediate, class:^(deadlock)$"
        #"immediate, class:^(gamescope)$" # Apply fullscreen to gamescope
        "immediate, class:^(steam_app).*, title:(.*)" # Apply fullscreen to Steam games

        # make Firefox PiP window floating and sticky
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"

        # float generic windows
        "float, title:^(Open Files)$"
        "float,title:^(File Upload)$"
        "float,title:^(File Operation Progress)$"
        "float, class:^(xdg-desktop-portal-gtk)$"
        "float, title:^(MainPicker)$"
        "float, title:^(.*Bitwarden Password Manager.*)$"

        # dim around specific applications
        "dimaround, class:^(xdg-desktop-portal-gtk)$"
        "dimaround, class:^(hyprpolkitagent)$"
        "dimaround, class:^(anyrun)$"

        "tag +apt, title:(Awakened PoE Trade)"
        "float, tag:apt"
        "noblur, tag:apt"
        "nofocus, tag:apt" # Disable auto-focus
        "noshadow, tag:apt"
        "noborder, tag:apt"
        "size 100% 100%, tag:apt"
        "center, tag:apt"

        # xwaylandvideobridge?!
        #"opacity 0.0 override,class:^(xwaylandvideobridge)$"
        #"noanim,class:^(xwaylandvideobridge)$"
        #"noinitialfocus,class:^(xwaylandvideobridge)$"
        #"maxsize 1 1,class:^(xwaylandvideobridge)$"
        #"noblur,class:^(xwaylandvideobridge)$"
      ];
      workspace = [
        "1, monitor:DP-1, default:true persistent:true"
        "9, monitor:HDMI-A-2, default:true persistent:true"
      ];
    };
  };
}
