_: {
  # dbus-broker is faster and more secure than dbus-daemon
  services.dbus.implementation = "broker";
}
