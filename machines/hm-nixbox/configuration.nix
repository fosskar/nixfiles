{ mylib, pkgs, ... }:
{
  imports = [
    ../../modules/zfs
    ../../modules/gpu
    ../../modules/cpu
  ]
  ++ (mylib.scanPaths ./. { exclude = [ "dashboards" ]; });

  nixpkgs.hostPlatform = "x86_64-linux";

  nixfiles = {
    gpu.intel.enable = true;
    cpu.amd.enable = true;
  };

  # systemd-boot doesn't support mirroredBoots yet (nixpkgs#152155)
  boot = {
    #kernelParams = [ "zfs.zfs_arc_max=12884901888" ]; # increase zfs arc size to 12gb
    kernelParams = [ "zfs.zfs_arc_max=17179869184" ]; # 16GB
    #kernelParams = [ "zfs.zfs_arc_max=34359738368" ];  # 32GB
    #kernelParams = [ "zfs.zfs_arc_max=42949672960" ];  # 40GB
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

  environment.systemPackages = with pkgs; [
    fontconfig
  ];

  services.tuned.enable = true;
}
