{
  config,
  lib,
  pkgs,
  ...
}:
let
  zfsCompatibleKernelPackages = lib.filterAttrs (
    name: kernelPackages:
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    && (builtins.tryEval kernelPackages).success
    && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
  ) pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
in
{
  boot = {
    kernelPackages = latestKernelPackage;

    supportedFilesystems = [ "zfs" ];

    initrd.supportedFilesystems = [ "zfs" ];

    zfs = {
      package = lib.mkDefault pkgs.zfs;
      forceImportRoot = lib.mkDefault false;
      devNodes = lib.mkDefault "/dev/disk/by-id"; # this is the default anways
    };
  };

  services.zfs = {
    autoScrub = {
      enable = lib.mkDefault true;
      interval = lib.mkDefault "monthly";
    };
    trim.enable = lib.mkDefault true;
    autoSnapshot.enable = lib.mkDefault true;
  };
}
