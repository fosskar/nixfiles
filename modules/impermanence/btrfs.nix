{ cfg }:
let
  devicePath = "/dev/disk/by-label/${cfg.btrfs.rootDeviceLabel}";
  deviceUnit = "dev-disk-by\\x2dlabel-${cfg.btrfs.rootDeviceLabel}.device";
in
{
  service = {
    btrfs-rollback = {
      description = "rollback btrfs root subvolume to a pristine state";
      wantedBy = [ "initrd.target" ];
      requires = [ deviceUnit ];
      after = [ deviceUnit ];
      before = [
        "-.mount"
        "sysroot.mount"
      ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p /tmp
        MNTPOINT=$(mktemp -d)
        (
          mount -t btrfs -o subvol=/ ${devicePath} "$MNTPOINT"
          trap 'umount "$MNTPOINT"' EXIT

          if [[ -e "$MNTPOINT/${cfg.btrfs.rootSubvolume}" ]]; then
            echo "backing up current root subvolume"
            mkdir -p "$MNTPOINT/old_roots"
            timestamp=$(date --date="@$(stat -c %Y "$MNTPOINT/${cfg.btrfs.rootSubvolume}")" "+%Y-%m-%d_%H:%M:%S")
            mv "$MNTPOINT/${cfg.btrfs.rootSubvolume}" "$MNTPOINT/old_roots/$timestamp"
          fi

          echo "cleaning old backups (>${toString cfg.btrfs.retentionDays} days)"
          find "$MNTPOINT/old_roots" -maxdepth 1 -mtime +${toString cfg.btrfs.retentionDays} -type d | while read -r old_root; do
            echo "deleting old backup: $old_root"
            btrfs subvolume delete "$old_root" || true
          done

          echo "creating fresh root subvolume"
          btrfs subvolume create "$MNTPOINT/${cfg.btrfs.rootSubvolume}"
        )
      '';
    };
  };
}
