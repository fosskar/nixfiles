_: {
  flake.modules."clan.service".snapshot-backup =
    { lib, ... }:
    {
      manifest.name = "snapshot-backup";
      manifest.description = "create filesystem snapshots for clan backup state";
      manifest.readme = builtins.readFile ./README.md;
      manifest.categories = [ "System" ];

      roles.client = {
        description = "machine exposing snapshot-backed state to backup providers";

        interface =
          { lib, ... }:
          {
            options = {
              folders = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                description = "live folders to snapshot before backup";
              };

              snapshotType = lib.mkOption {
                type = lib.types.enum [
                  "btrfs"
                  "zfs"
                ];
                description = "filesystem snapshot implementation";
              };
            };
          };

        perInstance =
          { settings, ... }:
          {
            nixosModule =
              { config, pkgs, ... }:
              let
                snapshotName = "borg-backup";
                # zfs unmounts idle .zfs/snapshot automounts (zfs_expire_snapshot), and
                # the borg job's own mount namespace cannot trigger them again
                # (openzfs#3512), so snapshots are mounted here explicitly. see README
                mountRoot = "/run/snapshot-backup";
                # the hooks run in the backup unit's mount namespace, where a mount is
                # not visible to the main process; mount in the host namespace, from
                # which mounts propagate into the unit's namespace
                inHostNs = "${pkgs.util-linux}/bin/nsenter --mount=/proc/1/ns/mnt --";
                state =
                  if settings.snapshotType == "zfs" then
                    {
                      # borg strips everything left of /./, so archives keep the live path
                      folders = map (folder: "${mountRoot}/.${folder}") settings.folders;
                      preBackupScript = ''
                        fail=0
                        datasets=""
                        for folder in ${lib.escapeShellArgs settings.folders}; do
                          if ! dataset=$(${pkgs.util-linux}/bin/findmnt -n -t zfs -o SOURCE "$folder"); then
                            echo "error: $folder is not a mounted zfs dataset" >&2
                            fail=1
                            continue
                          fi
                          datasets="$datasets $dataset"
                        done
                        [ "$fail" -eq 0 ] || exit 1
                        # borg reads only each dataset's own snapshot, where child
                        # dataset mountpoints appear empty; refuse to back up a
                        # dataset whose children are not listed as folders themselves.
                        for dataset in $datasets; do
                          for child in $(${config.boot.zfs.package}/bin/zfs list -H -o name -t filesystem -d 1 "$dataset" | tail -n +2); do
                            case " $datasets " in
                              *" $child "*) ;;
                              *)
                                echo "error: $dataset has child dataset $child, which is not a backup folder; its data would be missing" >&2
                                fail=1
                                ;;
                            esac
                          done
                        done
                        [ "$fail" -eq 0 ] || exit 1
                        for folder in ${lib.escapeShellArgs settings.folders}; do
                          dataset=$(${pkgs.util-linux}/bin/findmnt -n -t zfs -o SOURCE "$folder")
                          target="${mountRoot}$folder"
                          if ${inHostNs} ${pkgs.util-linux}/bin/mountpoint -q "$target"; then
                            echo "unmounting leftover snapshot mount: $target"
                            ${inHostNs} ${pkgs.util-linux}/bin/umount "$target"
                          fi
                          snapshots=$(${config.boot.zfs.package}/bin/zfs list -H -t snapshot -o name -d 1 "$dataset")
                          if printf '%s\n' "$snapshots" | grep -Fx -- "$dataset@${snapshotName}" >/dev/null; then
                            echo "deleting leftover zfs snapshot: $dataset@${snapshotName}"
                            ${config.boot.zfs.package}/bin/zfs destroy "$dataset@${snapshotName}"
                          fi
                          echo "creating zfs snapshot: $dataset@${snapshotName}"
                          ${config.boot.zfs.package}/bin/zfs snapshot "$dataset@${snapshotName}"
                          ${inHostNs} ${pkgs.coreutils}/bin/mkdir -p "$target"
                          ${inHostNs} ${pkgs.util-linux}/bin/mount -t zfs -o ro "$dataset@${snapshotName}" "$target"
                        done
                      '';
                      postBackupScript = ''
                        fail=0
                        for folder in ${lib.escapeShellArgs settings.folders}; do
                          if ! dataset=$(${pkgs.util-linux}/bin/findmnt -n -t zfs -o SOURCE "$folder"); then
                            echo "error: $folder is not a mounted zfs dataset" >&2
                            fail=1
                            continue
                          fi
                          target="${mountRoot}$folder"
                          if ${inHostNs} ${pkgs.util-linux}/bin/mountpoint -q "$target"; then
                            echo "unmounting snapshot: $target"
                            if ! ${inHostNs} ${pkgs.util-linux}/bin/umount "$target"; then
                              fail=1
                              continue
                            fi
                          fi
                          if ! snapshots=$(${config.boot.zfs.package}/bin/zfs list -H -t snapshot -o name -d 1 "$dataset"); then
                            fail=1
                            continue
                          fi
                          if printf '%s\n' "$snapshots" | grep -Fx -- "$dataset@${snapshotName}" >/dev/null; then
                            echo "destroying zfs snapshot: $dataset@${snapshotName}"
                            if ! ${config.boot.zfs.package}/bin/zfs destroy "$dataset@${snapshotName}"; then
                              fail=1
                            fi
                          fi
                        done
                        exit "$fail"
                      '';
                    }
                  else
                    {
                      folders = map (folder: "${folder}/.${snapshotName}") settings.folders;
                      preBackupScript = ''
                        fail=0
                        for folder in ${lib.escapeShellArgs settings.folders}; do
                          if ! ${pkgs.btrfs-progs}/bin/btrfs subvolume show "$folder" &>/dev/null; then
                            echo "error: $folder is not a btrfs subvolume" >&2
                            fail=1
                          fi
                        done
                        [ "$fail" -eq 0 ] || exit 1
                        for folder in ${lib.escapeShellArgs settings.folders}; do
                          snapshot="$folder/.${snapshotName}"
                          if [ -d "$snapshot" ]; then
                            echo "deleting leftover btrfs snapshot: $snapshot"
                            ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$snapshot"
                          fi
                          echo "creating btrfs snapshot: $snapshot"
                          ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot -r "$folder" "$snapshot"
                          ${pkgs.btrfs-progs}/bin/btrfs subvolume show "$snapshot" >/dev/null
                        done
                      '';
                      postBackupScript = ''
                        fail=0
                        for folder in ${lib.escapeShellArgs settings.folders}; do
                          snapshot="$folder/.${snapshotName}"
                          if [ -d "$snapshot" ]; then
                            echo "deleting btrfs snapshot: $snapshot"
                            if ! ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$snapshot"; then
                              fail=1
                            fi
                          fi
                        done
                        exit "$fail"
                      '';
                    };
              in
              {
                # folders point at snapshot paths, which are never writable restore
                # targets (.zfs/snapshot is virtual, btrfs staging may be a ro
                # snapshot); block clan backups restore before borg extract fails
                # with a confusing write error.
                clan.core.state.snapshot-backup = state // {
                  preRestoreScript = ''
                    echo "error: clan backups restore cannot write into snapshot paths" >&2
                    echo "follow the manual procedure in modules/clan-services/snapshot-backup/README.md" >&2
                    exit 1
                  '';
                };
              };
          };
      };
    };
}
