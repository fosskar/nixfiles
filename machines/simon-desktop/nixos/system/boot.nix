{ pkgs, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest; # pkgs.cachyosKernels.linuxPackages-cachyos-latest

    supportedFilesystems = [
      "ext4"
      "vfat"
      "tmpfs"
      "btrfs"
    ];
  };
}
