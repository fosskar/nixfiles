{
  flake.modules.nixos.preservation =
    {
      config,
      lib,
      inputs,
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

      # auto-derive partLabel from disko if available
      derivedPartLabel =
        if findBcachefsPartition != null then
          "disk-${findBcachefsPartition.diskName}-${findBcachefsPartition.partName}"
        else
          null;

      effectivePartLabel =
        if cfg.rollback.partLabel != null then cfg.rollback.partLabel else derivedPartLabel;

      effectiveCfg = cfg // {
        rollback = cfg.rollback // {
          partLabel = effectivePartLabel;
        };
      };

      # --- rollback backend services (inline; cfg = effectiveCfg) ---

      btrfsService =
        let
          devicePath = "/dev/disk/by-label/${effectiveCfg.rollback.deviceLabel}";
          deviceUnit = "dev-disk-by\\x2dlabel-${effectiveCfg.rollback.deviceLabel}.device";
        in
        {
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

                if [[ -e "$MNTPOINT/${effectiveCfg.rollback.subvolume}" ]]; then
                  echo "backing up current root subvolume"
                  mkdir -p "$MNTPOINT/old_roots"
                  timestamp=$(date --date="@$(stat -c %Y "$MNTPOINT/${effectiveCfg.rollback.subvolume}")" "+%Y-%m-%d_%H:%M:%S")
                  mv "$MNTPOINT/${effectiveCfg.rollback.subvolume}" "$MNTPOINT/old_roots/$timestamp"
                fi

                echo "cleaning old backups (>${toString effectiveCfg.rollback.retentionDays} days)"
                find "$MNTPOINT/old_roots" -maxdepth 1 -mtime +${toString effectiveCfg.rollback.retentionDays} -type d | while read -r old_root; do
                  echo "deleting old backup: $old_root"
                  btrfs subvolume list -o "$old_root" | sort -r | while read -r line; do
                    nested="''${line##* }"
                    btrfs subvolume delete "$MNTPOINT/$nested" || true
                  done
                  btrfs subvolume delete "$old_root" || true
                done

                echo "creating fresh root subvolume"
                btrfs subvolume create "$MNTPOINT/${effectiveCfg.rollback.subvolume}"
              )
            '';
          };
        };

      zfsService = {
        zfs-rollback-root = {
          description = "rollback zfs root to blank snapshot";
          wantedBy = [ "initrd.target" ];
          after = [ effectiveCfg.rollback.poolImportService ];
          before = [ "sysroot.mount" ];
          unitConfig.DefaultDependencies = "no";
          serviceConfig.Type = "oneshot";
          script = ''
            zfs rollback -r ${effectiveCfg.rollback.dataset}@${effectiveCfg.rollback.snapshot}
          '';
        };
      };

      bcachefsService =
        let
          devicePath = "/dev/disk/by-partlabel/${effectiveCfg.rollback.partLabel}";
          escapedLabel = builtins.replaceStrings [ "-" ] [ "\\x2d" ] effectiveCfg.rollback.partLabel;
          deviceUnit = "dev-disk-by\\x2dpartlabel-${escapedLabel}.device";
        in
        {
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

              if [[ -d "${effectiveCfg.rollback.subvolume}" ]]; then
                mkdir -p old_roots
                timestamp=$(date --date="@$(stat -c %Y "${effectiveCfg.rollback.subvolume}")" "+%Y-%m-%d_%H:%M:%S")
                mv "${effectiveCfg.rollback.subvolume}" "old_roots/$timestamp"
              fi

              find old_roots -maxdepth 1 -mtime +${toString effectiveCfg.rollback.retentionDays} -type d 2>/dev/null | while read -r old; do
                bcachefs subvolume delete "$old" || true
              done

              bcachefs subvolume create "${effectiveCfg.rollback.subvolume}"
            '';
          };
        };

      rollbackService =
        if cfg.rollback.type == "zfs" then
          zfsService
        else if cfg.rollback.type == "btrfs" then
          btrfsService
        else if cfg.rollback.type == "bcachefs" then
          bcachefsService
        else
          null;

      # --- preservation helpers ---

      toPreservationDir =
        d:
        let
          base = if builtins.isString d then { directory = d; } else d;
          withMode =
            if base.directory == "/var/lib/private" then base // { mode = base.mode or "0700"; } else base;
        in
        { how = "bindmount"; } // withMode;

      persistPath = "/persist";

      preserveCfg = config.preservation.preserveAt.${persistPath};

      getDirPath = d: if builtins.isString d then d else d.directory or "";
      getFilePath = f: if builtins.isString f then f else f.file or "";

      allPersistDirs = map getDirPath preserveCfg.directories;
      fileParentDirs = map (f: dirOf (getFilePath f)) preserveCfg.files;

      installDirs = lib.unique (lib.sort (a: b: a < b) (allPersistDirs ++ fileParentDirs));

      mountPoint = config.disko.rootMountPoint or "/mnt";
    in
    {
      imports = [ inputs.preservation.nixosModules.preservation ];

      options.preservation = {
        rollback = {
          type = lib.mkOption {
            type = lib.types.enum [
              "zfs"
              "btrfs"
              "bcachefs"
              "none"
            ];
            default = "none";
            description = "filesystem type for rollback";
          };

          dataset = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "zfs dataset to rollback (required for zfs)";
          };
          snapshot = lib.mkOption {
            type = lib.types.str;
            default = "blank";
            description = "zfs snapshot name to rollback to";
          };
          poolImportService = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "zfs import service to wait for (required for zfs)";
          };

          deviceLabel = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "label of the btrfs root device (required for btrfs)";
          };

          partLabel = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "GPT partition label of bcachefs device. Auto-derived from disko if not set.";
          };

          subvolume = lib.mkOption {
            type = lib.types.str;
            default = "@root";
            description = "name of root subvolume";
          };
          retentionDays = lib.mkOption {
            type = lib.types.int;
            default = 30;
            description = "days to keep old root backups";
          };
        };

      };

      config = {
        assertions = [
          {
            assertion = cfg.rollback.type != "zfs" || cfg.rollback.dataset != null;
            message = "preservation.rollback.dataset must be set when type is 'zfs'";
          }
          {
            assertion = cfg.rollback.type != "zfs" || cfg.rollback.poolImportService != null;
            message = "preservation.rollback.poolImportService must be set when type is 'zfs'";
          }
          {
            assertion = cfg.rollback.type != "btrfs" || cfg.rollback.deviceLabel != null;
            message = "preservation.rollback.deviceLabel must be set when type is 'btrfs'";
          }
          {
            assertion = cfg.rollback.type != "bcachefs" || effectivePartLabel != null;
            message = "preservation.rollback.partLabel must be set (or disko must have a bcachefs partition)";
          }
        ];

        boot.initrd.systemd.services = lib.mkIf (rollbackService != null) rollbackService;

        fileSystems.${persistPath}.neededForBoot = true;

        _module.args.preservationDiskoPostMountHook = lib.concatStringsSep "\n" (
          [ "# pre-create persistent directories for fresh install" ]
          ++ map (
            dir:
            let
              needsChmod = dir == "/var/lib/private";
              mkdirCmd = "mkdir -p ${mountPoint}${persistPath}${dir}";
              chmodCmd = lib.optionalString needsChmod " && chmod 0700 ${mountPoint}${persistPath}${dir}";
            in
            mkdirCmd + chmodCmd
          ) installDirs
        );

        # clan.core.settings.machine-id creates /etc/machine-id in the nix store,
        # causing systemd to mount a tmpfs overlay (for writability), which breaks
        # nix-optimise (EXDEV cross-device link). disable store-based file and let
        # preservation handle it via symlink. clan's kernel cmdline still works.
        environment.etc.machine-id.enable = lib.mkForce false;

        # point userborn at persistent storage so passwd/group/shadow survive
        # ephemeral root. userborn creates /etc symlinks automatically.
        services.userborn.passwordFilesLocation = lib.mkIf (config.services.userborn.enable or false
        ) "${persistPath}/etc";

        preservation = {
          enable = true;

          preserveAt.${persistPath} = {
            directories =
              map toPreservationDir [
                "/var/lib/nixos"
                "/var/lib/systemd"
                "/var/log"
              ]
              ++ lib.optional true {
                directory = "/var/lib/sops-nix";
                how = "bindmount";
                inInitrd = true;
              }
              ++ lib.optional true {
                directory = "/etc/secret-vars";
                how = "bindmount";
                inInitrd = true;
              };

            files = [
              {
                file = "/etc/machine-id";
                how = "symlink";
                inInitrd = true;
                createLinkTarget = true;
              }
            ];
          };
        };
      };
    };
}
