_: {
  services.flameshot.enable = true;

  # only autostart on x11, not wayland
  systemd.user.services.flameshot = {
    Unit.ConditionEnvironment = "XDG_SESSION_TYPE=x11";
  };
}
