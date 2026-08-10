_:
{ lib, ... }:
{
  _class = "clan.service";
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

          stateName = lib.mkOption {
            type = lib.types.strMatching "^[a-zA-Z0-9_-]+$";
            default = "snapshot-backup";
            description = "clan.core.state entry name";
          };

          snapshotName = lib.mkOption {
            type = lib.types.str;
            default = "borg-backup";
            description = "snapshot name";
          };
        };
      };

    perInstance =
      { settings, ... }:
      {
        nixosModule =
          { pkgs, ... }:
          let
            state =
              if settings.snapshotType == "zfs" then
                {
                  folders = map (folder: "${folder}/.zfs/snapshot/${settings.snapshotName}") settings.folders;
                  preBackupScript = ''
                    fail=0
                    for folder in ${lib.escapeShellArgs settings.folders}; do
                      dataset=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE "$folder" | grep -v '^/dev' || true)
                      if [ -z "$dataset" ]; then
                        echo "error: $folder is not a mounted zfs dataset" >&2
                        fail=1
                        continue
                      fi
                      # borg reads only the parent's .zfs/snapshot directory, where
                      # child dataset mountpoints appear empty; refuse to back up
                      # a dataset whose children would silently vanish.
                      if [ "$(${pkgs.zfs}/bin/zfs list -H -o name -d 1 "$dataset" | wc -l)" -gt 1 ]; then
                        echo "error: $dataset has child datasets; their data would be missing from $folder/.zfs/snapshot/${settings.snapshotName}" >&2
                        fail=1
                      fi
                    done
                    [ "$fail" -eq 0 ] || exit 1
                    for folder in ${lib.escapeShellArgs settings.folders}; do
                      dataset=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE "$folder" | grep -v '^/dev')
                      echo "creating zfs snapshot: $dataset@${settings.snapshotName}"
                      ${pkgs.zfs}/bin/zfs destroy -r "$dataset@${settings.snapshotName}" 2>/dev/null || true
                      ${pkgs.zfs}/bin/zfs snapshot -r "$dataset@${settings.snapshotName}"
                      ls "$folder/.zfs/snapshot/${settings.snapshotName}" >/dev/null
                    done
                  '';
                  postBackupScript = ''
                    for folder in ${lib.escapeShellArgs settings.folders}; do
                      dataset=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE "$folder" | grep -v '^/dev' || true)
                      if [ -n "$dataset" ]; then
                        echo "destroying zfs snapshot: $dataset@${settings.snapshotName}"
                        ${pkgs.zfs}/bin/zfs destroy -r "$dataset@${settings.snapshotName}" || true
                      fi
                    done
                  '';
                }
              else
                {
                  folders = map (folder: "${folder}/.${settings.snapshotName}") settings.folders;
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
                      snapshot="$folder/.${settings.snapshotName}"
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
                    for folder in ${lib.escapeShellArgs settings.folders}; do
                      snapshot="$folder/.${settings.snapshotName}"
                      if [ -d "$snapshot" ]; then
                        echo "deleting btrfs snapshot: $snapshot"
                        ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$snapshot"
                      fi
                    done
                  '';
                };
          in
          {
            clan.core.state.${settings.stateName} = state;
          };
      };
  };
}
