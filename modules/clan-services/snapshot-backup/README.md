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

## Restore

`clan backups restore` does not work for this state. The state `folders`
point at snapshot paths, and those paths are not writable restore targets:
`.zfs/snapshot` is a virtual read-only directory, and the btrfs staging
path may be a leftover read-only snapshot. The module sets a
`preRestoreScript` that fails with a pointer to this section. A direct
`borgbackup-restore` invocation bypasses that guard and fails inside
`borg extract` instead.

Restore manually:

1. List the archives and pick one:

   ```sh
   borg-job-storagebox list
   ```

2. Extract the snapshot paths into a staging directory with enough free
   space (on `nixbox` use a directory under `/tank`):

   ```sh
   mkdir /tank/restore-staging && cd /tank/restore-staging
   borg-job-storagebox extract <archive> tank/apps/.zfs/snapshot/borg-backup
   ```

   borg stores paths without the leading slash. For btrfs the archived
   path is for example `persist/.borg-backup`.

3. Stop the services that write into the target folders, then copy the
   extracted content into the live folders:

   ```sh
   rsync -a /tank/restore-staging/tank/apps/.zfs/snapshot/borg-backup/ /tank/apps/
   ```

4. Start the services again and delete the staging directory.

## Interaction with borg excludes

Backup sources are snapshot paths, not the live paths. A borg exclude
written as a bare path never matches: `/var/log` does not match
`/persist/.borg-backup/var/log`. Write excludes depth-insensitive with
the `sh:` style, for example `sh:**/var/log`. The borgbackup instance in
`inventory/backup.nix` follows this rule.

A live database inside a snapshotted folder is torn at snapshot time.
Give such a service a dump-style `clan.core.state` entry that writes a
consistent copy in `preBackupScript`, and add an exclude for the live
file. See `clan.core.state.netbird-server` for the pattern.

## Settings

- `folders`: live folders to snapshot before backup.
- `snapshotType`: filesystem implementation, either `zfs` or `btrfs`.
- `stateName`: `clan.core.state` entry name. defaults to `snapshot-backup`.
- `snapshotName`: snapshot name. defaults to `borg-backup`.
