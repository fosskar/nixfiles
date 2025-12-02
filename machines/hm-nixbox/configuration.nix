# hm-nixbox - bare-metal nixos server replacing proxmox
# migrated from 14 lxc containers to single host
{ lib, mylib, ... }:
{
  imports = [
    ../../modules/bare-metal
    ../../modules/shared
    ../../modules/zfs
  ]
  ++ (mylib.scanPaths ./. { });

  nixpkgs.hostPlatform = "x86_64-linux";

  # override bare-metal default (systemd-boot) with grub for mirrored ESP
  # systemd-boot doesn't support mirroredBoots yet (nixpkgs#152155)
  boot = {
    kernelParams = [ "zfs.zfs_arc_max=12884901888" ]; # increase zfs arc size to 12gb
    kernelModules = [ "nct6775" ];
    loader = {
      systemd-boot.enable = false;
      grub = {
        enable = true;
        device = "nodev";
        mirroredBoots = [
          {
            devices = [ "nodev" ];
            path = "/boot";
          }
          {
            devices = [ "nodev" ];
            path = "/boot-fallback";
          }
        ];
      };
    };
    # auto-import tank pool at boot
    zfs.extraPools = [ "tank" ];
  };
  # german console keyboard layout
  console.keyMap = "de";
}
