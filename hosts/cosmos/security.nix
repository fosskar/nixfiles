{pkgs, ...}: {
  services.gnome.gnome-keyring.enable = true;

  security = {
    sudo.wheelNeedsPassword = false;
    pam = {
      services = {
        greetd.enableGnomeKeyring = true;
        # allow wayland lockers to unlock the screen
        #pam.services.swaylock.text = "auth include login";   # switched to hyprlock
        hyprlock.text = "auth include login";
      };
      loginLimits = [
        {
          domain = "@users";
          item = "rtprio";
          type = "-";
          value = 1;
        }
      ];
    };
    polkit.enable = true;
    # userland niceness
    rtkit.enable = true;
  };

  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = ["graphical-session.target"];
      wants = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
