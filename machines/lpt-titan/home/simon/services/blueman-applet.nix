_: {
  services.blueman-applet.enable = true;

  # only start blueman-applet on x11 sessions
  systemd.user.services.blueman-applet.Unit.ConditionEnvironment = "XDG_SESSION_TYPE=x11";
}
