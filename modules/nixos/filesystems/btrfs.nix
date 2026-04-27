{
  flake.modules.nixos.btrfs = {
    boot = {
      supportedFilesystems = [ "btrfs" ];
      initrd.supportedFilesystems = [ "btrfs" ];
    };

    # monthly scrub catches silent bitrot/checksum errors. mirrors the
    # services.zfs.autoScrub default in modules/nixos/filesystems/zfs.nix.
    services.btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
    };
  };
}
