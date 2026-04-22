{
  flake.modules.nixos.workstation = _: {
    # dbus-broker is faster and more secure than dbus-daemon
    services.dbus.implementation = "broker";
  };
}
