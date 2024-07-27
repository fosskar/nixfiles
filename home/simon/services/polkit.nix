{ pkgs, ... }:
{
  # user space systemd polkit service
  # start the Pantheon policykit agent
  # this is based on the GNOME policykit agent
  # but uses a newer GTK version
  systemd.user.services.polkit-pantheon-authentication-agent-1 = {
    Unit = {
      Description = "Pantheon PolicyKit agent";
      Wants = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.pantheon.pantheon-agent-polkit}/libexec/policykit-1-pantheon/io.elementary.desktop.agent-polkit";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}
