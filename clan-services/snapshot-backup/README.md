## Usage

```nix
inventory.instances = {
  snapshot-backup = {
    module = {
      name = "snapshot-backup";
      input = "self";
    };
    roles.client.machines."machine".settings = {
      snapshotType = "zfs"; # or "btrfs"
      folders = [ "/tank/apps" ];
    };
  };
};
```

Use this together with the clan-core `borgbackup` service. `snapshot-backup` does not create borg repositories or run backup jobs itself.

## Overview

`snapshot-backup` exposes live folders as snapshot-backed `clan.core.state` entries. Backup providers such as clan-core `borgbackup` then back up the snapshot paths instead of the mutable live folders.

Backup flow:

1. `preBackupScript` creates filesystem snapshots for `folders`.
2. borg backs up the generated snapshot paths.
3. `postBackupScript` removes the snapshots after the backup.

This gives borg a stable point-in-time view while services keep writing to the live filesystem.

## Snapshot types

### `zfs`

For each configured folder, the service finds the mounted ZFS dataset and creates a recursive snapshot named `snapshotName`.

Live folder:

```text
/tank/apps
```

Backup source:

```text
/tank/apps/.zfs/snapshot/borg-backup
```

### `btrfs`

Each configured folder must be a btrfs subvolume. The service creates a read-only subvolume snapshot under the folder.

Live folder:

```text
/persist
```

Backup source:

```text
/persist/.borg-backup
```

## Settings

- `folders`: live folders to snapshot before backup.
- `snapshotType`: filesystem implementation, either `zfs` or `btrfs`.
- `stateName`: `clan.core.state` entry name. defaults to `snapshot-backup`.
- `snapshotName`: snapshot name. defaults to `borg-backup`.
