# zfs: legacy mountpoints for every mounted dataset

every zfs dataset this repo mounts uses `mountpoint=legacy` and is declared in `fileSystems`. systemd owns all zfs mounts; `zfs-mount.service` owns none.

this covers the disko-managed root pool `znixos` and the hand-made data pool `tank` on `nixbox`. datasets on data pools such as `tank` are declared with `nixfiles.zfs.datasets` (`modules/nixos/filesystems/zfs/datasets.nix`), which generates the `fileSystems` entries.

## options considered

| option                                     | zfs `mountpoint`   | who mounts                           | verdict  |
| ------------------------------------------ | ------------------ | ------------------------------------ | -------- |
| legacy + `fileSystems`                     | `legacy`           | systemd `.mount` units               | chosen   |
| native + `fileSystems` with `zfsutil`      | path, e.g. `/tank` | `.mount` units **and** `zfs-mount`   | rejected |
| native only, pool in `boot.zfs.extraPools` | path               | `zfs-mount.service` (`zfs mount -a`) | rejected |

## why legacy

### one owner per dataset

with native mountpoints plus `fileSystems`, two things mount the same dataset after the pool import: the `.mount` unit and `zfs mount -a`. nothing orders them against each other. this is a known race (nixpkgs [#212762](https://github.com/NixOS/nixpkgs/issues/212762), disko [#581](https://github.com/nix-community/disko/issues/581)). a nixpkgs maintainer on it ([#529602](https://github.com/NixOS/nixpkgs/pull/529602#issuecomment-4662740442)): "You cannot have `zfs-mount.service` and a systemd mount unit handling the same dataset. They race… it's luck if it ever worked."

`zfs mount -a` ignores legacy datasets, so with legacy the race cannot happen.

### it is the documented nixos default

- `boot.zfs.extraPools` option description: "Usually … set the mountpoint property … to `legacy` and add the ZFS filesystems to `fileSystems`"
- nixos wiki, "ZFS conflicting with systemd": disable `zfs-mount`, drop the `fileSystems` entries, or use legacy
- nixpkgs maintainers (ElvishJerricco in #529602, wizeman in #212762) recommend legacy for datasets mounted at boot

disko's default (a disko `mountpoint` without `options.mountpoint = "legacy"`) produces the native + `zfsutil` setup and is affected by the race. in this repo every mounted disko `zfs_fs` sets `options.mountpoint = "legacy"`.

### real mount units

legacy datasets get systemd `.mount` units from `fileSystems`. services order on them with `RequiresMountsFor=`, and a failed mount shows up as a failed unit.

native-only via `extraPools` was rejected for this reason: `zfs mount -a` mounts every dataset in one oneshot, with no per-dataset units to depend on, and this repo stopped using `extraPools` because those mounts came up too late.

### portability is not lost

`zpool export tank` / `zpool import tank` moves the pool between machines in either mode. only automatic mounting after import differs: on a foreign system, mount legacy datasets by hand (`mount -t zfs tank/apps /mnt/apps`) or set `mountpoint` there once.

## incident that led to this

2026-10-09: `tank` was switched from legacy to native mountpoints with `zfsutil` in `fileSystems`. on the next boot `zfs mount -a` won the race; `tank.mount` failed with `zfs_mount_at() failed: mountpoint or dataset is busy`, the child `.mount` units failed on dependency, and about 30 services with `RequiresMountsFor=/tank/...` (garage, opencloud, the arr stack, jellyfin, …) did not start. the change was reverted the same day with `zfs set -u mountpoint=legacy tank`.

2026-10-10: splitting `tank` into per-service datasets changed `zfs-import-tank.service` on every deploy. each switch stopped it, which unmounted all of `tank` and restarted every service on it for a few seconds; see [import unit restarts](#import-unit-restarts).

## `nixfiles.zfs.datasets`

datasets on data pools are declared by name, next to the service that uses them or in the machine config:

```nix
nixfiles.zfs.datasets."tank/apps/immich".properties = {
  recordsize = "1M";
  "com.sun:auto-snapshot" = "true";
};
```

for each dataset the module generates:

- a `fileSystems` entry at `/<name>` (or `mountPoint`) with `nofail` and `x-systemd.before=local-fs.target`
- a oneshot `zfs-dataset-<name>.service`, ordered after `zfs-import-<pool>` and before the mount, that creates the dataset with `mountpoint=legacy` and the properties if it is missing, and otherwise re-applies the properties with `zfs set`

behaviour:

- datasets are never destroyed. removing a property from nix does not reset it in the pool; set it to `none` or `zfs inherit` it by hand
- the oneshot refuses to create a dataset over a non-empty directory, which would hide the data below the new mount. the mount then fails and its services do not start. existing directories are migrated by hand (copy into the new dataset, swap, then declare it)
- `mountPoint = null` creates the dataset with `mountpoint=none` and no `fileSystems` entry, e.g. `tank/reserved`
- datasets on pools imported in the initrd (root pools such as `znixos`) are rejected; disko manages those
- the oneshot is only wanted by its mount, not required, and restarts without stopping first, so a property change on switch never unmounts anything

### mount ordering

`nofail` keeps a failed mount from failing the boot, but also drops the mount's ordering before `local-fs.target`. `x-systemd.before=local-fs.target` restores it, so `systemd-tmpfiles-setup` and services see the mounted dataset. owner and mode of a dataset's top directory then come from the services' own tmpfiles rules (e.g. the nixpkgs immich module's `e /tank/apps/immich 0700 immich immich`), not from this module.

services still need `RequiresMountsFor=` on their data path; some nixpkgs modules only require their state directory (immich needed an explicit `RequiresMountsFor` on its media location).

### import unit restarts

nixos's `zfs-import-<pool>.service` lists every mount of the pool in `Before=`, so adding or removing a dataset, or a zfs package update, changes the unit. switch then stopped it, which stopped every mount of the pool and every service on them. the module sets `restartIfChanged = false` on the import unit of each pool with declared datasets; the pool stays imported, so there is nothing to redo.

### adding a dataset for a new service

1. declare `nixfiles.zfs.datasets."tank/<path>"` with its properties
2. make sure the service has `RequiresMountsFor=/tank/<path>` and a tmpfiles rule or `StateDirectory` for ownership
3. deploy; switch creates and mounts the dataset before the service writes to it

gotcha: a dataset created by hand without a declaration is never mounted. a service then writes into the plain directory on the parent dataset, and snapshots, quotas and properties of the new dataset do not apply. check with `findmnt /tank/<path>`.

## related

- backups: `snapshot-backup` snapshots each folder's dataset on its own and refuses datasets whose child datasets are not backup folders themselves, so a parent that only holds child datasets (`tank/apps`) is not a backup folder
- `/etc/zfs/zpool.cache` is persisted via preservation (`modules/nixos/boot/preservation/default.nix`), as the nixos manual recommends
- `zfs-mount.service` stays enabled; with only legacy datasets it mounts nothing, and the paperless/papra bindfs mounts declare `x-systemd.requires=zfs-mount.service`

## references

- [nixos zfs module](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/tasks/filesystems/zfs.nix) (`boot.zfs.extraPools` description)
- [nixos wiki: ZFS](https://wiki.nixos.org/wiki/ZFS)
- [nixos manual: zfs state](https://github.com/NixOS/nixpkgs/blob/master/nixos/doc/manual/administration/zfs-state.section.md)
- [zfsconcepts(7): mount points](https://openzfs.github.io/openzfs-docs/man/master/7/zfsconcepts.7.html)
- nixpkgs [#212762](https://github.com/NixOS/nixpkgs/issues/212762), [#529602](https://github.com/NixOS/nixpkgs/pull/529602), disko [#581](https://github.com/nix-community/disko/issues/581)
