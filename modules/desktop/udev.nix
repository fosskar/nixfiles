{ config, ... }:
let
  # zfs has its own i/o scheduler, so use none for all devices
  # btrfs/ext4/xfs rely on kernel scheduler, so use bfq for hdds (desktop responsiveness)
  useZfs = config.boot.zfs.enabled or false;
  hddScheduler = if useZfs then "none" else "bfq";
in
{
  services.udev.extraRules = ''
    # i/o schedulers: ${hddScheduler} for hdds, none for ssds/nvme
    ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="${hddScheduler}"
    ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
  '';
}
