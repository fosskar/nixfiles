{
  pkgs,
  config,
  lib,
  ...
}:
{
  boot.zfs.package = pkgs.zfsUnstable;

  services.zfs = lib.mkIf config.boot.zfs.enabled {
    autoSnapshot.enable = lib.mkDefault false; # FIXME for now
    # defaults to 12, which is a bit much given how much data is written
    autoSnapshot.monthly = lib.mkDefault 1;
    autoScrub.enable = lib.mkDefault true;
  };
  environment.systemPackages = lib.mkIf config.boot.zfs.enabled [
    pkgs.zfs-prune-snapshots
  ];
}
