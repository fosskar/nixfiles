{ mylib, pkgs, ... }:
{
  imports = [
    ../../modules/zfs
    ../../modules/tailscale
  ]
  ++ (mylib.scanPaths ./. { exclude = [ "dashboards" ]; });

  nixfiles.tailscale.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";

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
        copyKernels = true; # required when /boot is on separate partition from /
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

  services.tuned.enable = true;
}
