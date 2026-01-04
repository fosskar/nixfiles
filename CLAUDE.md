# claude code context

## overview

this repo is built on [clan-core](https://docs.clan.lol/) - a framework for managing nixos machines with:

- inventory-based machine/service configuration
- automatic secrets management (vars)
- deployment tooling

## machines

| machine       | type    | description                       |
| ------------- | ------- | --------------------------------- |
| simon-desktop | desktop | daily driver workstation          |
| lpt-titan     | laptop  | framework 13                      |
| hm-nixbox     | server  | home server, self-hosted services |
| hzc-pango     | vps     | hetzner, reverse proxy (pangolin) |

IPs in `machines/flake-part.nix` under `inventory.machines` and `instances.internet`.

### ssh access

ssh config has `User root` set, so:

```bash
ssh <machine>.clan              # .clan tld (clan-core)
ssh <machine>.lan               # .lan tld (local network)
clan ssh <machine>              # via clan CLI
```

## repo structure

- `machines/` - per-host nixos configs
- `machines/flake-part.nix` - clan inventory, services, deploy targets
- `modules/` - reusable nixos modules under `nixfiles.*` namespace
- `modules/profiles/` - base profiles (server, workstation) applied via tags
- `users/` - home-manager configs per user
- `lib/` - mylib helpers
- `vars/` - clan-generated secrets/config per machine

## principles

- **declarative first** - avoid manual changes, everything should be in nix config
- if something needs manual intervention, find a way to declare it instead
- **troubleshoot remotely** - don't ask user to check machines, ssh in and debug yourself
- **no deploy without permission** - never run `clan machines update` or deploy to machines without explicit user instruction
- **ATOMIC COMMITS** - one logical change per commit. NEVER bundle unrelated changes. use `jj split` to separate changes before committing. examples of separate commits:
  - refactor module → one commit
  - update docs for that refactor → separate commit
  - unrelated config change → separate commit

## patterns

- `mylib.scanPaths ./. { }` - auto-import all .nix files in directory
- `nixfiles.<category>.<feature>.enable` - module option convention
- **importing a module enables it** - no extra `nixfiles.*.enable = true` needed
- `lib.mkDefault` for overridable defaults in profiles
- `lib.mkForce` to override conflicting services

## clan-core

### commands

```bash
nh os switch                    # switch locally
clan machines update <machine>  # deploy remote (or local)
clan install                    # install new machine
clan vars generate              # generate missing vars
ssh root@<machine>.clan         # .clan is default tld from clan-core
```

### inventory (`machines/flake-part.nix`)

```nix
flake.clan.inventory = {
  machines.<name> = {
    deploy.targetHost = "root@<ip>";
    tags = [ "server" "home" ];
  };
  instances.<service> = {
    module = { name = "<module>"; input = "clan-core"; };
    roles.<role> = {
      machines.<name> = { };    # specific machines
      tags.<tag> = { };         # or apply by tag
      settings = { ... };
      extraModules = [ ... ];
    };
  };
};
```

### tags

- `server` → `modules/profiles/server`
- `desktop`, `laptop` → `modules/profiles/workstation`
- `home`, `hetzner` - location grouping
- `all` - all machines

### clan services in use

| service            | module    | purpose                             |
| ------------------ | --------- | ----------------------------------- |
| admin              | (builtin) | ssh key management                  |
| users              | clan-core | user creation + home-manager        |
| clan-cache         | clan-core | trusted nix caches                  |
| yggdrasil          | (builtin) | mesh networking                     |
| internet           | (builtin) | IP exports for yggdrasil peering    |
| syncthing          | clan-core | folder sync (desktop ↔ laptop)     |
| borgbackup         | clan-core | backups to hetzner storagebox       |
| server-module      | importer  | applies server profile via tag      |
| workstation-module | importer  | applies workstation profile via tag |

### vars

- `vars/per-machine/<machine>/` - machine-specific generated secrets
- `vars/shared/` - shared across machines
- auto-generated: syncthing keys, borgbackup keys, passwords, ssh keys, etc
- encrypted with sops (age + yubikey/tpm)

## secrets

- clan vars handles most secrets automatically
- `sops.secrets."<name>"` for manual secrets (u2f keys, api tokens, etc)
- secrets decrypted at activation, available at runtime paths

## nix commands

repo has direnv + nix flake devshell - tools available automatically when in repo.

```bash
nix fmt                         # format nix files
nix flake check                 # run checks
nix build .#nixosConfigurations.<machine>.config.system.build.toplevel
nix eval .#nixosConfigurations.<machine>.config.<option> --json
nix shell nixpkgs#<pkg>         # temporary tool outside devshell
```

## monitoring

metrics are stored in VictoriaMetrics on hm-nixbox. when looking for metrics, query there.

## persistence

some machines use preservation/impermanence (opt-in state). root filesystem is ephemeral, only explicitly persisted paths survive reboot. check `nixfiles.persistence.backend` - either "preservation" (preferred) or "impermanence". see `docs/preservation.md` for why we switched.

## desktop shell

- `nixfiles.quickshell` - "dms", "noctalia", or "none"
- `nixfiles.machineType` - "desktop" or "laptop"
- dms: use `settings.json` directly, not nix attrset (simpler to maintain)
- way-displays: always takes control of scaling, no passthrough to niri

## vcs

jj (jujutsu) colocated with git. jj calls commits "changes".

```bash
jj commit -m "msg"              # describe current change + create new change
jj describe -m "msg"            # only describe, stays on same change
jj new                          # create new change on top
jj split -m "msg" -- <files>    # extract files into separate change
jj bookmark set main -r @       # move main bookmark (only when ready to push)
jj git push                     # push
```

workflow: commit working changes, continue on new change. bookmark + push only when ready.
