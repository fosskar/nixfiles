{
  flake.modules.nixos.preservationRollbackBcachefs =
    {
      config,
      lib,
      utils,
      ...
    }:
    let
      cfg = config.preservation;

      # find bcachefs partition from disko config
      findBcachefsPartition = lib.pipe (config.disko.devices.disk or { }) [
        (lib.mapAttrsToList (
          diskName: disk:
          lib.mapAttrsToList (partName: part: {
            inherit diskName partName;
            type = part.content.type or "";
          }) (disk.content.partitions or { })
        ))
        lib.flatten
        (lib.findFirst (p: p.type == "bcachefs") null)
      ];

      derivedPartLabel =
        if findBcachefsPartition != null then
          "disk-${findBcachefsPartition.diskName}-${findBcachefsPartition.partName}"
        else
          null;

      effectivePartLabel =
        if cfg.rollback.partLabel != null then cfg.rollback.partLabel else derivedPartLabel;

      devicePath = "/dev/disk/by-partlabel/${effectivePartLabel}";
      escapedLabel = builtins.replaceStrings [ "-" ] [ "\\x2d" ] effectivePartLabel;
      deviceUnit = "dev-disk-by\\x2dpartlabel-${escapedLabel}.device";

      # mirror the bcachefs.nix logic so we wait for the actual first unlock
      # service instead of hardcoding unlock-bcachefs--.service.
      bcachefsBootFs = lib.filterAttrs (
        _: fs: fs.fsType == "bcachefs" && utils.fsNeededForBoot fs
      ) config.fileSystems;
      unlockServices = lib.sort (a: b: a < b) (
        lib.mapAttrsToList (mp: _: "unlock-bcachefs-${utils.escapeSystemdPath mp}") bcachefsBootFs
      );
      firstUnlock = if unlockServices == [ ] then null else lib.head unlockServices;
    in
    lib.mkIf (cfg.rollback.type == "bcachefs") {
      assertions = [
        {
          assertion = effectivePartLabel != null;
          message = "preservation.rollback.partLabel must be set (or disko must have a bcachefs partition)";
        }
      ];

      boot.initrd.systemd.services.bcachefs-rollback = {
        description = "rollback bcachefs root subvolume";
        wantedBy = [ "initrd.target" ];
        requires = [ deviceUnit ];
        after = [ deviceUnit ] ++ lib.optional (firstUnlock != null) "${firstUnlock}.service";
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

          if [[ -d "${cfg.rollback.subvolume}" ]]; then
            mkdir -p old_roots
            timestamp=$(date --date="@$(stat -c %Y "${cfg.rollback.subvolume}")" "+%Y-%m-%d_%H:%M:%S")
            mv "${cfg.rollback.subvolume}" "old_roots/$timestamp"
          fi

          if [[ -d old_roots ]]; then
            find old_roots -maxdepth 1 -mtime +${toString cfg.rollback.retentionDays} -type d | while read -r old; do
              bcachefs subvolume delete "$old" || true
            done || true
          fi

          bcachefs subvolume create "${cfg.rollback.subvolume}"
        '';
      };
    };
}
