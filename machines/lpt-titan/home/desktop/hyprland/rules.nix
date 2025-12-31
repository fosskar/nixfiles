_: {
  wayland.windowManager.hyprland = {
    settings = {
      windowrule = [
        # webcord
        "match:class ^(WebCord)$, workspace 9 silent"

        # steam
        "match:class ^(steam)$, workspace 9 silent"

        # ts3
        "match:title ^(TeamSpeak 3)$, workspace 9 silent"

        # suppress notification events when gaming
        "match:class .*, suppress_event maximize"
        "match:class ^(cs2)$, suppress_event maximize fullscreen"

        # steam notifications
        "match:class ^(steam)$ match:title ^(.*)$, no_initial_focus yes"
        "match:class ^(steam)$ match:title ^(notificationtoasts.*)$ match:floating 1, no_initial_focus yes"

        # idle inhibit on any fullscreen app
        "match:class ^(.*)$, idle_inhibit focus"
        "match:title ^(.*)$, idle_inhibit focus"
        "match:fullscreen 1, idle_inhibit always"

        # immediate for games
        "match:class ^(cs2)$, immediate yes"
        "match:class ^(deadlock)$, immediate yes"
        "match:class ^(gamescope)$, immediate yes"
        "match:class ^(steam_app).*, immediate yes"

        # prevent blur/transparency on gamescope windows
        "match:class ^(gamescope)$, no_blur yes"
        "match:class ^(gamescope)$, opaque yes"
        "match:class ^(gamescope)$, no_anim yes"
        "match:class ^(gamescope)$, opacity 1.0 override 1.0 override 1.0 override"

        # make Firefox PiP window floating and sticky
        "match:title ^(Picture-in-Picture)$, float yes"
        "match:title ^(Picture-in-Picture)$, pin yes"

        # float generic windows
        "match:title ^(Open Files)$, float yes"
        "match:title ^(File Upload)$, float yes"
        "match:title ^(File Operation Progress)$, float yes"
        "match:class ^(xdg-desktop-portal-gtk)$, float yes"
        "match:title ^(MainPicker)$, float yes"
        "match:title ^(.*Bitwarden.*)$, float yes"

        # dim around specific applications
        "match:class ^(xdg-desktop-portal-gtk)$, dim_around on"
        "match:class ^(hyprpolkitagent)$, dim_around on"
        "match:class ^(anyrun)$, dim_around on"

        #"match:title (Awakened PoE Trade), tag +apt"
        #"match:tag apt, float"
        #"match:tag apt, noblur"
        #"match:tag apt, nofocus"
        #"match:tag apt, noshadow"
        #"match:tag apt, noborder"
        #"match:tag apt, size 100% 100%"
        #"match:tag apt, center"

        # xwaylandvideobridge?!
        #"match:class ^(xwaylandvideobridge)$, opacity 0.0 override"
        #"match:class ^(xwaylandvideobridge)$, noanim"
        #"match:class ^(xwaylandvideobridge)$, noinitialfocus"
        #"match:class ^(xwaylandvideobridge)$, maxsize 1 1"
        #"match:class ^(xwaylandvideobridge)$, noblur"
      ];
      workspace = [
        "1, monitor:DP-1, default:true persistent:true"
        "9, monitor:HDMI-A-2, default:true persistent:true"
      ];
    };
  };
}
