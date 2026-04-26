{
  flake.modules.nixos.preservationRollbackBtrfs =
    { config, lib, ... }:
    let
      cfg = config.preservation;
      devicePath = "/dev/disk/by-label/${cfg.rollback.deviceLabel}";
      deviceUnit = "dev-disk-by\\x2dlabel-${cfg.rollback.deviceLabel}.device";
    in
    lib.mkIf (cfg.rollback.type == "btrfs") {
      boot.initrd.systemd.services.btrfs-rollback = {
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

            if [[ -e "$MNTPOINT/${cfg.rollback.subvolume}" ]]; then
              echo "backing up current root subvolume"
              mkdir -p "$MNTPOINT/old_roots"
              timestamp=$(date --date="@$(stat -c %Y "$MNTPOINT/${cfg.rollback.subvolume}")" "+%Y-%m-%d_%H:%M:%S")
              mv "$MNTPOINT/${cfg.rollback.subvolume}" "$MNTPOINT/old_roots/$timestamp"
            fi

            echo "cleaning old backups (>${toString cfg.rollback.retentionDays} days)"
            find "$MNTPOINT/old_roots" -maxdepth 1 -mtime +${toString cfg.rollback.retentionDays} -type d 2>/dev/null | while read -r old_root; do
              echo "deleting old backup: $old_root"
              btrfs subvolume list -o "$old_root" | sort -r | while read -r line; do
                nested="''${line##* }"
                btrfs subvolume delete "$MNTPOINT/$nested" || true
              done
              btrfs subvolume delete "$old_root" || true
            done

            echo "creating fresh root subvolume"
            btrfs subvolume create "$MNTPOINT/${cfg.rollback.subvolume}"
          )
        '';
      };
    };
}
