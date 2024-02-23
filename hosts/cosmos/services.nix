{
  config,
  lib,
  pkgs,
  ...
}: {
  services = {
    gnome.gnome-keyring.enable = true;
    printing.enable = true;
    openssh.enable = true;
    fstrim.enable = true;
    thermald.enable = true;
    #flatpak.enable = true;
    ratbagd.enable = true;

    udev.extraRules = lib.mkMerge [
      ## rules below set the scheduler to bfq for rotational drives, bfq for SSD/eMMC drives and none for NVMe drives
      # HDD
      ''ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"''
      # SSD
      ''ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="bfq"''
      # NVMe SSD
      ''ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"''
    ];
  };
}
