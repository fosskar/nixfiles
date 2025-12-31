{ pkgs, lib, ... }:
{
  services = {
    xidlehook = {
      enable = true;
      detect-sleep = true;
      not-when-audio = true;
      not-when-fullscreen = true;
      timers = [
        {
          # Turn off the display after 3 minutes (180 seconds)
          delay = 180;
          command = "xset dpms force off";
        }
        {
          # Lock the screen after 10 minutes (600 seconds)
          delay = 600;
          command = "${pkgs.i3lock}/bin/i3lock -nFc 232528";
        }
        {
          # Suspend the laptop after an additional 15 minutes (total 25 minutes)
          delay = 900;
          command = "systemctl -i suspend";
        }
      ];
    };
  };

  # override default DISPLAY condition - XWayland creates DISPLAY in wayland too
  systemd.user.services.xidlehook = {
    Unit.ConditionEnvironment = lib.mkForce "XDG_SESSION_TYPE=x11";
  };
}
