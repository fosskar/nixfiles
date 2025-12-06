{ mylib, pkgs, ... }:
{
  imports = [
    ../../modules/bare-metal
    ../../modules/shared
    ../../modules/zfs
  ]
  ++ (mylib.scanPaths ./. { exclude = [ "dashboards" ]; });

  nixpkgs.hostPlatform = "x86_64-linux";

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
    zfs.extraPools = [ "tank" ];
  };
  console.keyMap = "de";

  environment.systemPackages = with pkgs; [
    fontconfig
  ];
}
