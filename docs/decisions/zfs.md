# zfs: legacy mountpoints for every mounted dataset

every zfs dataset this repo mounts uses `mountpoint=legacy` and is declared in `fileSystems`. systemd owns all zfs mounts; `zfs-mount.service` owns none.

this covers the disko-managed root pool `znixos` and the hand-made data pool `tank` on `nixbox`.

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

## adding a dataset

1. `zfs create -o mountpoint=legacy tank/<name>`. children of a legacy dataset inherit `legacy`, so a plain `zfs create` works too.
2. add the `fileSystems."/tank/<name>"` entry (`fsType = "zfs"`, `options = [ "nofail" ]`).
3. services using it need `RequiresMountsFor=/tank/<name>`.

gotcha: a legacy dataset without a `fileSystems` entry is never mounted. a service then writes into the plain directory on the parent dataset, and snapshots, quotas and properties of the new dataset do not apply. check with `findmnt /tank/<name>`.

## related

- `/etc/zfs/zpool.cache` is persisted via preservation (`modules/nixos/boot/preservation/default.nix`), as the nixos manual recommends
- `zfs-mount.service` stays enabled; with only legacy datasets it mounts nothing, and the paperless/papra bindfs mounts declare `x-systemd.requires=zfs-mount.service`

## references

- [nixos zfs module](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/tasks/filesystems/zfs.nix) (`boot.zfs.extraPools` description)
- [nixos wiki: ZFS](https://wiki.nixos.org/wiki/ZFS)
- [nixos manual: zfs state](https://github.com/NixOS/nixpkgs/blob/master/nixos/doc/manual/administration/zfs-state.section.md)
- [zfsconcepts(7): mount points](https://openzfs.github.io/openzfs-docs/man/master/7/zfsconcepts.7.html)
- nixpkgs [#212762](https://github.com/NixOS/nixpkgs/issues/212762), [#529602](https://github.com/NixOS/nixpkgs/pull/529602), disko [#581](https://github.com/nix-community/disko/issues/581)
