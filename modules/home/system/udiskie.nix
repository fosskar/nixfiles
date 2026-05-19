_: {
  flake.modules.homeManager.udiskie = _: {
    services.udiskie = {
      enable = true;
      automount = true;
      notify = true;
      tray = "auto";
    };

    systemd.user.services.udiskie.Unit.ConditionEnvironment = "WAYLAND_DISPLAY";
  };
}
