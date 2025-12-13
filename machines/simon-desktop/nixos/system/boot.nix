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

    initrd.systemd.services.btrfs-rollback = {
      description = "Rollback btrfs root dataset to blank snapshot";
      wantedBy = [ "initrd.target" ];
      requires = [ "dev-disk-by\\x2dpartlabel-disk\\x2dmain\\x2droot.device" ];
      after = [ "dev-disk-by\\x2dpartlabel-disk\\x2dmain\\x2droot.device" ];
      before = [
        "-.mount"
        "sysroot.mount"
      ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir /btrfs_tmp -p
        MNTPOINT=$(mktemp -d)
        (
          mount -t btrfs -o subvol=/ /dev/disk/by-label/nixos "$MNTPOINT"
          trap 'umount "$MNTPOINT"' EXIT

          if [[ -e "$MNTPOINT/@root" ]]; then
            echo "Backing up current @root subvolume"
            mkdir -p "$MNTPOINT/old_roots"
            timestamp=$(date --date="@$(stat -c %Y "$MNTPOINT/@root")" "+%Y-%m-%d_%H:%M:%S")
            mv "$MNTPOINT/@root" "$MNTPOINT/old_roots/$timestamp"
          fi

          echo "Cleaning old backups (>7 days)"
          find "$MNTPOINT/old_roots" -maxdepth 1 -mtime +7 -type d | while read -r old_root; do
            echo "Deleting old backup: $old_root"
            btrfs subvolume delete "$old_root" || true
          done

          echo "Creating fresh @root subvolume"
          btrfs subvolume create "$MNTPOINT/@root"
        )
      '';
    };
  };
}
