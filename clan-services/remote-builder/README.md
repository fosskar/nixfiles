## Usage

```nix
inventory.instances = {
  remote-builder = {
    module = {
      name = "remote-builder";
      input = "self";
    };
    roles.builder.machines."builder" = { };
    roles.client.tags.all = { };
  };
};
```

## Overview

`remote-builder` wires Nix distributed builds between clan machines.

Builder role:

- creates user `nix-remote-builder`, trusted for Nix builds
- authorizes client SSH public keys from clan vars
- enables Nix features needed for `ssh-ng`, cgroups, auto-allocated UIDs, and recursive Nix
- derives `max-jobs` and feature enablement from its role settings
- runs hourly garbage collection toward a free-space target

Client role:

- generates an ed25519 SSH key with clan vars
- enables `nix.distributedBuilds`
- adds all builder machines to `nix.buildMachines`, with `maxJobs`,
  `systems`, `speedFactor`, and `supportedFeatures` read from each
  builder's role settings
- uses `ssh-ng` as user `nix-remote-builder`

Machines assigned both `builder` and `client` skip client config, so builders
do not offload to themselves. This rule is intentionally encoded in both
roles: the builder filters builders out of the authorized client keys, and
the client no-ops on builder machines.

## Settings

Per-builder settings on `roles.builder.machines.<machine>.settings`:

- `maxJobs` (default `8`): parallel builds on the builder; the same number
  is advertised to every client, so the builder cap and the client
  dispatch weight cannot drift apart
- `systems` (default `[ "x86_64-linux" ]`): systems advertised to clients
- `speedFactor` (default `10`): relative speed advertised to clients
- `supportedFeatures` (default `nixos-test`, `big-parallel`, `kvm`,
  `uid-range`, `recursive-nix`): advertised to clients; `uid-range` and
  `recursive-nix` also enable the matching `system-features` (and
  `recursive-nix` the experimental feature) on the builder
- `gcKeepFreeGiB` (default `128`): free-space target the hourly garbage
  collection maintains on `/nix/store`
- `extraClientKeys` (default `[ ]`): ssh pubkeys for non-clan clients
  allowed to offload builds; each key is added to `nix-remote-builder`
  authorized_keys with the same `restrict,command="nix-daemon --stdio"`
  restriction as clan clients

```nix
roles.builder.machines."builder".settings.extraClientKeys = [
  "ssh-ed25519 AAAA... foreign-machine"
];
```

The foreign machine still configures itself as a nix remote builder client
manually (`/etc/nix/machines` or `nix.buildMachines`) using the matching
private key and `sshUser = "nix-remote-builder"`.
