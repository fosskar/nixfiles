{
  config,
  lib,
  pkgs,
  ...
}:
let
  isUnstable = config.boot.zfs.package == pkgs.zfs_unstable or pkgs.zfsUnstable;
  zfsCompatibleKernelPackages = lib.filterAttrs (
    name: kernelPackages:
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    && (builtins.tryEval kernelPackages).success
    && (
      let
        zfsPackage =
          if isUnstable then
            kernelPackages.zfs_unstable
          else
            kernelPackages.${pkgs.zfs.kernelModuleAttribute};
      in
      !(zfsPackage.meta.broken or false)
    )
  ) pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
in
{
  boot = {
    kernelPackages = lib.mkIf (lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.zfs) latestKernelPackage;

    #networking.hostId = lib.mkDefault "8425e349";

    supportedFilesystems = [ "zfs" ];

    initrd.supportedFilesystems = [ "zfs" ];

    zfs = {
      package = lib.mkDefault pkgs.zfs;
      forceImportRoot = lib.mkDefault false;
      devNodes = lib.mkDefault "/dev/disk/by-id"; # this is the default anways
    };
  };

  services.zfs = lib.mkIf config.boot.zfs.enabled {
    autoScrub = {
      enable = lib.mkDefault true;
      interval = lib.mkDefault "monthly";
    };
    trim.enable = lib.mkDefault true;
    autoSnapshot = {
      enable = lib.mkDefault true;
      frequent = 0;
      hourly = 24;
      daily = 7;
      weekly = 4;
      monthly = 3;
    };
  };
}
