# zfs snapshot support for borgbackup
{
  lib,
  pkgs,
  cfg,
}:
let
  snapshotName = "borg-backup";
in
{
  # transform folders to .zfs/snapshot paths
  transformFolders = folders: map (f: "${f}/.zfs/snapshot/${snapshotName}") folders;

  # create recursive snapshots before backup
  preBackupScript = ''
    for folder in ${lib.escapeShellArgs cfg.folders}; do
      dataset=$(${pkgs.zfs}/bin/zfs list -H -o name,mountpoint | ${pkgs.gawk}/bin/awk -v path="$folder" '$2 == path {print $1}')
      if [ -n "$dataset" ]; then
        echo "creating zfs snapshot: $dataset@${snapshotName}"
        ${pkgs.zfs}/bin/zfs snapshot -r "$dataset@${snapshotName}"
        # trigger automount of snapshot
        ls "$folder/.zfs/snapshot/${snapshotName}" >/dev/null
      fi
    done
  '';

  # destroy snapshots after backup
  postBackupScript = ''
    for folder in ${lib.escapeShellArgs cfg.folders}; do
      dataset=$(${pkgs.zfs}/bin/zfs list -H -o name,mountpoint | ${pkgs.gawk}/bin/awk -v path="$folder" '$2 == path {print $1}')
      if [ -n "$dataset" ]; then
        echo "destroying zfs snapshot: $dataset@${snapshotName}"
        ${pkgs.zfs}/bin/zfs destroy -r "$dataset@${snapshotName}" || true
      fi
    done
  '';
}
