{ mylib, pkgs, ... }:
{
  imports = [
    ../../modules/zfs
    ../../modules/gpu
    ../../modules/cpu
    ../../modules/power
  ]
  ++ (mylib.scanPaths ./. { exclude = [ "dashboards" ]; });

  nixpkgs.hostPlatform = "x86_64-linux";

  nixfiles = {
    gpu.intel.enable = true;
    cpu.amd.enable = true;
    power.tuned = {
      enable = true;
      profile = [
        "server-powersave"
        "spindown-disk"
      ];
    };
  };

  # systemd-boot doesn't support mirroredBoots yet (nixpkgs#152155)
  boot = {
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
}
