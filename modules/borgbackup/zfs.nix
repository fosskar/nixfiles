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
      # use findmnt to get dataset name (works with legacy mounts)
      dataset=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE "$folder" | grep -v '^/dev')
      if [ -n "$dataset" ]; then
        echo "creating zfs snapshot: $dataset@${snapshotName}"
        ${pkgs.zfs}/bin/zfs destroy -r "$dataset@${snapshotName}" 2>/dev/null || true
        ${pkgs.zfs}/bin/zfs snapshot -r "$dataset@${snapshotName}"
        # trigger automount of snapshot
        ls "$folder/.zfs/snapshot/${snapshotName}" >/dev/null
      fi
    done
  '';

  # destroy snapshots after backup
  postBackupScript = ''
    for folder in ${lib.escapeShellArgs cfg.folders}; do
      # use findmnt to get dataset name (works with legacy mounts)
      dataset=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE "$folder" | grep -v '^/dev')
      if [ -n "$dataset" ]; then
        echo "destroying zfs snapshot: $dataset@${snapshotName}"
        ${pkgs.zfs}/bin/zfs destroy -r "$dataset@${snapshotName}" || true
      fi
    done
  '';
}
