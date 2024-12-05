_: {
  security.polkit = {
    enable = true;
  };
  services.accounts-daemon.enable = true;

  # Fuse filesystem that returns symlinks to executables based on the PATH of the requesting process. This is useful to execute shebangs on NixOS that assume hard coded locations in locations like /bin or /usr/bin etc.
  services.envfs.enable = true;
}
