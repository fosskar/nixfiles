{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.borgbackup;

  btrfs = import ./btrfs.nix { inherit lib pkgs cfg; };
  zfs = import ./zfs.nix { inherit lib pkgs cfg; };

  # select snapshot helpers based on type
  snapshot = if cfg.snapshotType == "zfs" then zfs else btrfs;

  # transform folders to snapshot paths if using snapshots
  backupFolders = if cfg.useSnapshots then snapshot.transformFolders cfg.folders else cfg.folders;
in
{
  options.nixfiles.borgbackup = {
    enable = lib.mkEnableOption "borgbackup state configuration for clan";

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
      description = "filesystem type for snapshots (must match the filesystem of your backup folders)";
    };
  };

  config = lib.mkIf cfg.enable {
    clan.core.state.backup = {
      folders = backupFolders;
    }
    // lib.optionalAttrs cfg.useSnapshots {
      inherit (snapshot) preBackupScript postBackupScript;
    };
  };
}
