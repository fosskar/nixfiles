_: {
  services.network-manager-applet.enable = true;

  # only start nm-applet on x11 sessions
  systemd.user.services.network-manager-applet.Unit.ConditionEnvironment = "XDG_SESSION_TYPE=x11";
}
