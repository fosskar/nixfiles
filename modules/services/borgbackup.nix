{
  flake.modules.nixos.borgbackup =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      snapshotName = "borg-backup";

      btrfsHelpers = {
        transformFolders = folders: map (f: "${f}/.${snapshotName}") folders;
        preBackupScript = ''
          for folder in ${lib.escapeShellArgs cfg.folders}; do
            snapshot="$folder/.${snapshotName}"
            if ${pkgs.btrfs-progs}/bin/btrfs subvolume show "$folder" &>/dev/null; then
              echo "creating btrfs snapshot: $snapshot"
              ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot -r "$folder" "$snapshot"
            fi
          done
        '';
        postBackupScript = ''
          for folder in ${lib.escapeShellArgs cfg.folders}; do
            snapshot="$folder/.${snapshotName}"
            if [ -d "$snapshot" ]; then
              echo "deleting btrfs snapshot: $snapshot"
              ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$snapshot"
            fi
          done
        '';
      };

      zfsHelpers = {
        transformFolders = folders: map (f: "${f}/.zfs/snapshot/${snapshotName}") folders;
        preBackupScript = ''
          for folder in ${lib.escapeShellArgs cfg.folders}; do
            dataset=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE "$folder" | grep -v '^/dev')
            if [ -n "$dataset" ]; then
              echo "creating zfs snapshot: $dataset@${snapshotName}"
              ${pkgs.zfs}/bin/zfs destroy -r "$dataset@${snapshotName}" 2>/dev/null || true
              ${pkgs.zfs}/bin/zfs snapshot -r "$dataset@${snapshotName}"
              ls "$folder/.zfs/snapshot/${snapshotName}" >/dev/null
            fi
          done
        '';
        postBackupScript = ''
          for folder in ${lib.escapeShellArgs cfg.folders}; do
            dataset=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE "$folder" | grep -v '^/dev')
            if [ -n "$dataset" ]; then
              echo "destroying zfs snapshot: $dataset@${snapshotName}"
              ${pkgs.zfs}/bin/zfs destroy -r "$dataset@${snapshotName}" || true
            fi
          done
        '';
      };

      cfg = config.nixfiles.borgbackup;
      snapshot = if cfg.snapshotType == "zfs" then zfsHelpers else btrfsHelpers;
      backupFolders = if cfg.useSnapshots then snapshot.transformFolders cfg.folders else cfg.folders;
    in
    {
      options.nixfiles.borgbackup = {
        folders = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "/persist" ];
          description = "folders to backup via clan.core.state";
        };

        useSnapshots = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "create filesystem snapshot before backup for consistency";
        };

        snapshotType = lib.mkOption {
          type = lib.types.enum [
            "btrfs"
            "zfs"
          ];
          default = "btrfs";
          description = "filesystem type for snapshots";
        };
      };

      config = {
        clan.core.state.backup = {
          folders = backupFolders;
        }
        // lib.optionalAttrs cfg.useSnapshots {
          inherit (snapshot) preBackupScript postBackupScript;
        };
      };
    };
}
