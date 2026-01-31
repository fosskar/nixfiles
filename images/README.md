# images

bootable iso/vm images for installation and recovery.

## build

```bash
nix build .#vm-base
```

output: `result/iso/nixos-*.iso`

## available images

| image   | purpose                                  |
| ------- | ---------------------------------------- |
| vm-base | minimal installation iso with ssh access |

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

## adding new images

1. create `<name>.nix` importing appropriate module from `${modulesPath}/installer/`
2. add to `flake-module.nix` packages using `lib.nixosSystem` + `.config.system.build.<format>`

common formats:

- `isoImage` - bootable iso
- `sdImage` - raspberry pi / arm boards
- `vmwareImage` - vmware ova
- `amazonImage` - aws ami
