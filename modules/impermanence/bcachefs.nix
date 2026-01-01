{ cfg }:
let
  devicePath = "/dev/disk/by-partlabel/${cfg.rollback.partLabel}";
  deviceUnit = "dev-disk-by\\x2dpartlabel-${cfg.rollback.partLabel}.device";
in
{
  service = {
    bcachefs-rollback = {
      description = "rollback bcachefs root subvolume to a pristine state";
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
          # unlock and mount bcachefs
          bcachefs unlock ${devicePath} || true
          mount -t bcachefs ${devicePath} "$MNTPOINT"
          trap 'umount "$MNTPOINT"' EXIT

          cd "$MNTPOINT"

          if [[ -d "${cfg.rollback.subvolume}" ]]; then
            echo "backing up current root subvolume"
            mkdir -p old_roots
            timestamp=$(date --date="@$(stat -c %Y "${cfg.rollback.subvolume}")" "+%Y-%m-%d_%H:%M:%S")
            bcachefs subvolume snapshot "${cfg.rollback.subvolume}" "old_roots/$timestamp"

            echo "deleting current root subvolume"
            bcachefs subvolume delete "${cfg.rollback.subvolume}"
          fi

          echo "cleaning old backups (>${toString cfg.rollback.retentionDays} days)"
          find old_roots -maxdepth 1 -mtime +${toString cfg.rollback.retentionDays} -type d 2>/dev/null | while read -r old_root; do
            echo "deleting old backup: $old_root"
            bcachefs subvolume delete "$old_root" || true
          done

          echo "creating fresh root subvolume"
          bcachefs subvolume create "${cfg.rollback.subvolume}"
        )
      '';
    };
  };
}
