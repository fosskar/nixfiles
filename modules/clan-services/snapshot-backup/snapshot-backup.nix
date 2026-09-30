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
              { pkgs, ... }:
              let
                snapshotName = "borg-backup";
                state =
                  if settings.snapshotType == "zfs" then
                    {
                      folders = map (folder: "${folder}/.zfs/snapshot/${snapshotName}") settings.folders;
                      preBackupScript = ''
                        fail=0
                        for folder in ${lib.escapeShellArgs settings.folders}; do
                          if ! dataset=$(${pkgs.util-linux}/bin/findmnt -n -t zfs -o SOURCE "$folder"); then
                            echo "error: $folder is not a mounted zfs dataset" >&2
                            fail=1
                            continue
                          fi
                          # borg reads only the parent's .zfs/snapshot directory, where
                          # child dataset mountpoints appear empty; refuse to back up
                          # a dataset whose children would silently vanish.
                          if [ "$(${pkgs.zfs}/bin/zfs list -H -o name -d 1 "$dataset" | wc -l)" -gt 1 ]; then
                            echo "error: $dataset has child datasets; their data would be missing from $folder/.zfs/snapshot/${snapshotName}" >&2
                            fail=1
                          fi
                        done
                        [ "$fail" -eq 0 ] || exit 1
                        for folder in ${lib.escapeShellArgs settings.folders}; do
                          dataset=$(${pkgs.util-linux}/bin/findmnt -n -t zfs -o SOURCE "$folder")
                          snapshots=$(${pkgs.zfs}/bin/zfs list -H -t snapshot -o name -d 1 "$dataset")
                          if printf '%s\n' "$snapshots" | grep -Fx -- "$dataset@${snapshotName}" >/dev/null; then
                            echo "deleting leftover zfs snapshot: $dataset@${snapshotName}"
                            ${pkgs.zfs}/bin/zfs destroy -r "$dataset@${snapshotName}"
                          fi
                          echo "creating zfs snapshot: $dataset@${snapshotName}"
                          ${pkgs.zfs}/bin/zfs snapshot -r "$dataset@${snapshotName}"
                          ls "$folder/.zfs/snapshot/${snapshotName}" >/dev/null
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
                          if ! snapshots=$(${pkgs.zfs}/bin/zfs list -H -t snapshot -o name -d 1 "$dataset"); then
                            fail=1
                            continue
                          fi
                          if printf '%s\n' "$snapshots" | grep -Fx -- "$dataset@${snapshotName}" >/dev/null; then
                            echo "destroying zfs snapshot: $dataset@${snapshotName}"
                            if ! ${pkgs.zfs}/bin/zfs destroy -r "$dataset@${snapshotName}"; then
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
