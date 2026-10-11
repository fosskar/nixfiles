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
      folders = [ "/tank/apps/immich" ];
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

For each configured folder, the service finds the mounted ZFS dataset, creates a snapshot named `snapshotName` and mounts it read-only below `/run/snapshot-backup`. `postBackupScript` unmounts it and destroys the snapshot. A dataset with child datasets is refused unless every child is a configured folder too, because the parent's snapshot shows child mount points as empty directories.

Live folder:

```text
/tank/apps/immich
```

Backup source and archive path:

```text
/run/snapshot-backup/./tank/apps/immich   # passed to borg create
tank/apps/immich                          # stored in the archive
```

#### Why the snapshot is mounted explicitly

ZFS exposes snapshots under `<dataset>/.zfs/snapshot/<name>` and mounts them on first access. Reading that path directly from borg is unreliable:

- the ZFS module performs the automount by running `mount` in the initial mount namespace, so a process in its own mount namespace cannot trigger it ([openzfs/zfs#3512](https://github.com/openzfs/zfs/issues/3512)). The clan-core borg job runs with `ProtectSystem=strict`, which gives it such a namespace
- ZFS unmounts an automounted snapshot again once it was not accessed for `zfs_expire_snapshot` seconds (default 300, [zfs(4)](https://openzfs.github.io/openzfs-docs/man/master/4/zfs.4.html)). the unmount propagates into the borg job's namespace
- triggering the automount on the host before borg starts therefore only works while borg reaches the dataset before it expires. with several datasets, the ones borg reaches later stay idle while earlier paths are read, expire, and are archived as empty directories without any error. this happened on 2026-10-11 after `tank/apps` was split into per-service datasets

An explicit `mount -t zfs -o ro <dataset>@<snapshot> <dir>` does not expire. borgmatic's ZFS hook works this way: it snapshots the dataset, temporarily mounts the snapshot in its runtime directory and stores the files at their original path ([borgmatic ZFS docs](https://torsion.org/borgmatic/reference/configuration/data-sources/zfs/)).

#### Why the mount happens in the host namespace

borgmatic mounts and runs borg in one process, so both share a mount namespace. Here the steps are split across systemd phases: the clan-core borg job runs `preBackupScript` as `ExecStartPre=+` and `borg create` as `ExecStart`. On this setup (systemd 261) a mount made by the `ExecStartPre=+` command is not visible to the main process, even though both report the same mount namespace. The scripts therefore run `mount`, `umount` and `mountpoint` through `nsenter --mount=/proc/1/ns/mnt`: the mount is created in the host namespace and propagates into the job's namespace, the same path the `.zfs/snapshot` automount takes, but without the expiry.

#### Archive paths

The folder is passed to borg as `/run/snapshot-backup/./<folder>`. borg 1.4 strips everything left of `/./` from archived paths (the "slashdot hack", [borg create](https://borgbackup.readthedocs.io/en/1.4-maint/usage/create.html)), so the archive stores the live path and excludes match it, e.g. `sh:**/tank/apps/immich/encoded-video`. The mount point is the same on every run, which keeps borg's files cache valid; borgmatic recommends a fixed runtime directory for the same reason.

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
the zfs snapshot mounts are read-only, and the btrfs staging
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
