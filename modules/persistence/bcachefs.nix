{ cfg }:
let
  devicePath = "/dev/disk/by-partlabel/${cfg.rollback.partLabel}";
  # systemd escaping: "-" becomes "\x2d" in unit names
  escapedLabel = builtins.replaceStrings [ "-" ] [ "\\x2d" ] cfg.rollback.partLabel;
  deviceUnit = "dev-disk-by\\x2dpartlabel-${escapedLabel}.device";
in
{
  service = {
    bcachefs-rollback = {
      description = "rollback bcachefs root subvolume";
      wantedBy = [ "initrd.target" ];
      requires = [ deviceUnit ];
      after = [
        deviceUnit
        "unlock-bcachefs--.service"
      ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = false;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        KeyringMode = "inherit";
      };
      script = ''
        set -euo pipefail
        keyctl link @u @s || true
        mkdir -p /tmp
        MNTPOINT=$(mktemp -d)
        mount -t bcachefs ${devicePath} "$MNTPOINT"
        trap 'cd /; umount "$MNTPOINT"; rmdir "$MNTPOINT"' EXIT
        cd "$MNTPOINT"

        # archive existing @root if present
        if [[ -d "${cfg.rollback.subvolume}" ]]; then
          mkdir -p old_roots
          timestamp=$(date --date="@$(stat -c %Y "${cfg.rollback.subvolume}")" "+%Y-%m-%d_%H:%M:%S")
          mv "${cfg.rollback.subvolume}" "old_roots/$timestamp"
        fi

        # cleanup old roots > retention days
        find old_roots -maxdepth 1 -mtime +${toString cfg.rollback.retentionDays} -type d 2>/dev/null | while read -r old; do
          bcachefs subvolume delete "$old" || true
        done

        # create fresh root subvolume
        bcachefs subvolume create "${cfg.rollback.subvolume}"
      '';
    };
  };
}
