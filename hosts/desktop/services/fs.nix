{ lib, ... }:
{
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
  # enable the unified cgroup hierarchy (cgroupsv2)
  # NOTE: we use mkForce ensure that we are making cgroupsv2 the default
  # some services, i.e. lxd,  tries to disable it
  systemd.enableUnifiedCgroupHierarchy = lib.mkForce true;
}
