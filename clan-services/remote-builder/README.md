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

- creates system user `nix`
- trusts user `nix` for Nix builds
- authorizes client SSH public keys from clan vars
- enables Nix features needed for `ssh-ng`, cgroups, auto-allocated UIDs, and recursive Nix
- sets builder defaults for parallel builds

Client role:

- generates an ed25519 SSH key with clan vars
- enables `nix.distributedBuilds`
- adds all builder machines to `nix.buildMachines`
- uses `ssh-ng` as user `nix`

Machines assigned both `builder` and `client` skip client config, so builders do not offload to themselves.

## Settings

`roles.builder.<machine>.settings.extraClientKeys`: list of ssh pubkeys for
non-clan clients allowed to offload builds. Each key is added to
`nix-remote-builder` authorized_keys with the same
`restrict,command="nix-daemon --stdio"` restriction as clan clients.

```nix
roles.builder.machines."builder".settings.extraClientKeys = [
  "ssh-ed25519 AAAA... foreign-machine"
];
```

The foreign machine still configures itself as a nix remote builder client
manually (`/etc/nix/machines` or `nix.buildMachines`) using the matching
private key and `sshUser = "nix-remote-builder"`.

Otherwise no role settings; builder/client behavior is derived from role
assignment.
