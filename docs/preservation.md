# preservation over impermanence

this repo switched from [impermanence](https://github.com/nix-community/impermanence) to [preservation](https://github.com/nix-community/preservation) for opt-in state persistence.

## why switch

### alignment with nixos direction

nixos is moving toward **interpreter-less boot** - removing bash and other interpreters from the critical boot path for security. this is part of [nixos security phase 2](https://github.com/nix-community/projects/blob/main/proposals/nixpkgs-security-phase2.md).

**impermanence** uses:

- bash scripts in nixos activation scripts
- custom systemd services with bash to manage mounts/permissions
- works with both scripted and systemd initrd

**preservation** uses:

- static systemd mount units generated at build time
- systemd-tmpfiles rules (no runtime scripts)
- requires `boot.initrd.systemd.enable` (no scripted initrd)

preservation generates pure systemd configuration - no interpreters needed at runtime.

### technical differences

| aspect         | impermanence                    | preservation                          |
| -------------- | ------------------------------- | ------------------------------------- |
| implementation | bash activation scripts         | static systemd mount units + tmpfiles |
| initrd         | scripted or systemd             | systemd only                          |
| config style   | magic runtime logic             | explicit (when, how, permissions)     |
| scope          | nixos + standalone home-manager | nixos only                            |
| mount options  | `hideMounts` (x-gvfs-hide)      | configurable `commonMountOptions`     |

### why this matters

1. **security**: fewer interpreters in boot = smaller attack surface
2. **predictability**: static config vs runtime decisions
3. **future-proof**: systemd initrd is where nixos is headed
4. **debuggability**: can inspect generated mount units directly

## config

```nix
nixfiles.persistence = {
  enable = true;
  rollback.type = "btrfs";  # or "zfs", "bcachefs"
  rollback.deviceLabel = "nixos";
  directories = [ "/var/lib/myapp" ];
  files = [ "/etc/myconfig" ];
};
```

note: preservation requires `boot.initrd.systemd.enable = true`.

## references

- [preservation docs](https://nix-community.github.io/preservation/)
- [preservation vs impermanence comparison](https://nix-community.github.io/preservation/impermanence-comparison.html)
- [nixos security phase 2](https://github.com/nix-community/projects/blob/main/proposals/nixpkgs-security-phase2.md)
