# btrfs snapshot support for borgbackup
{
  lib,
  pkgs,
  cfg,
}:
let
  snapshotName = "borg-backup";
in
{
  # transform folders to snapshot paths
  transformFolders = folders: map (f: "${f}/.${snapshotName}") folders;

  # create read-only snapshots before backup
  preBackupScript = ''
    for folder in ${lib.escapeShellArgs cfg.folders}; do
      snapshot="$folder/.${snapshotName}"
      if ${pkgs.btrfs-progs}/bin/btrfs subvolume show "$folder" &>/dev/null; then
        echo "creating btrfs snapshot: $snapshot"
        ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot -r "$folder" "$snapshot"
      fi
    done
  '';

  # delete snapshots after backup
  postBackupScript = ''
    for folder in ${lib.escapeShellArgs cfg.folders}; do
      snapshot="$folder/.${snapshotName}"
      if [ -d "$snapshot" ]; then
        echo "deleting btrfs snapshot: $snapshot"
        ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$snapshot"
      fi
    done
  '';
}
