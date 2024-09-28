_: {
  services.fstrim = {
    enable = true;
    # The timer interval passed to the systemd service. The default is monthly
    # but we prefer trimming weekly as the system receives a lot of writes.
    interval = "weekly";
  };

  # Firefox cache on tmpfs
  fileSystems."/home/simon/.cache/mozilla/firefox" = {
    device = "tmpfs";
    fsType = "tmpfs";
    noCheck = true;
    options = [
      "noatime"
      "nodev"
      "nosuid"
      "size=128M"
    ];
  };
  # zen browser cache on tmpfs
  fileSystems."/home/simon/.cache/zen" = {
    device = "tmpfs";
    fsType = "tmpfs";
    noCheck = true;
    options = [
      "noatime"
      "nodev"
      "nosuid"
      "size=128M"
    ];
  };
}
