{
  flake.modules.nixos.zfs =
    {
      config,
      flake-self,
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

        kernelParams = [
          "zfs.zfs_arc_max=17179869184" # 16GB
        ];

        supportedFilesystems = [ "zfs" ];

        initrd.supportedFilesystems = [ "zfs" ];

        zfs = {
          package = lib.mkDefault pkgs.zfs_unstable;
          forceImportRoot = lib.mkDefault false;
          devNodes = lib.mkDefault "/dev/disk/by-id";
        };
      };

      services.zfs = lib.mkIf config.boot.zfs.enabled {
        autoScrub = {
          enable = lib.mkDefault true;
          interval = lib.mkDefault "monthly";
        };
        trim.enable = lib.mkDefault true;
        # zed mail auto-enables when msmtp's sendmail wrapper is present
        # (services.zfs.zed.enableMail default). only the recipient is missing.
        zed.settings = {
          ZED_EMAIL_ADDR = [ "zfs@${flake-self.domains.local}" ];
          ZED_NOTIFY_VERBOSE = true;
        };
        # clan-core enables zfs-auto-snapshot without mkDefault; sanoid replaces it
        autoSnapshot.enable = lib.mkForce false;
      };

      # datasets opt in with services.sanoid.datasets.<name>.useTemplate = [ "standard" ]
      services.sanoid = lib.mkIf config.boot.zfs.enabled {
        enable = lib.mkDefault true;
        # periods left unset fall back to sanoid.defaults.conf (hourly 48, daily 90, monthly 6)
        templates.standard = {
          frequently = 0;
          hourly = 0;
          daily = 14;
          weekly = 4;
          monthly = 6;
          yearly = 0;
          autosnap = true;
          autoprune = true;
        };
      };

      environment.systemPackages = [ pkgs.zfs-prune-snapshots ];
    };
}
