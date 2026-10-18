# images

bootable iso/vm images for installation and recovery.

images are flake packages defined in `modules/flake-parts/iso-images.nix`. they are not machine configs; they reuse nixos modules to build installers and rescue environments.

## build

```bash
nix build .#vm-base
```

output: `result/iso/nixos-*.iso`

## available images

| image              | purpose                                                  |
| ------------------ | -------------------------------------------------------- |
| vm-base            | minimal installation iso with ssh access                 |
| ha-green-installer | sd card installer for the home assistant green (aarch64) |

## vm-base

minimal nixos iso for:

- new machine installation via `clan install`
- recovery/rescue access

includes:

- ssh with authorized keys (root)
- qemu guest agent
- minimal firmware

boot in vm:

```bash
qemu-system-x86_64 -enable-kvm -m 2G -cdrom result/iso/*.iso
```

## ha-green-installer

sd card image that boots the home assistant green into a nixos installer with root ssh access. the green's u-boot (in the first 16 MiB of its emmc) tries the sd card before the emmc, so no button or u-boot change is needed.

```bash
nix build .#packages.aarch64-linux.ha-green-installer
zstd -d --stdout result/sd-image/*.img.zst | sudo dd of=/dev/<sd card> bs=4M conv=fsync status=progress
```

boot the green with the card inserted, then install to the emmc with `clan machines install ha-green --target-host root@192.168.10.50`.

## adding new images

1. create `<name>.nix` importing appropriate module from `${modulesPath}/installer/`
2. add to `flake-module.nix` packages using `lib.nixosSystem` + `.config.system.build.<format>`

common formats:

- `isoImage` - bootable iso
- `sdImage` - raspberry pi / arm boards
- `vmwareImage` - vmware ova
- `amazonImage` - aws ami
