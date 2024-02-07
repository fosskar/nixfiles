{pkgs, ...}: {
  security.polkit.enable = true;
  security.pam.services.swaylock = {};
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  ## breaks gamescope in steam. this should set CAP_SYS_NICE for gamescope but didnt work
  #security.wrappers.gamescope = {
  #  owner = "root";
  #  group = "root";
  #  source = "${pkgs.gamescope}/bin/gamescope";
  #  capabilities = "cap_sys_nice=eip";
  #};

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
