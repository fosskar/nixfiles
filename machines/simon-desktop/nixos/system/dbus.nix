_: {
  services.dbus = {
    enable = true;
    # packages are added automatically by other modules (gnome-keyring, seahorse, gnome-disks, etc.)
    # implementation = "broker" is now the default
  };
}
