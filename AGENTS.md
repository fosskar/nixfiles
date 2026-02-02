# claude code context

## overview

this repo is built on [clan-core](https://docs.clan.lol/) - a framework for managing nixos machines with:

- inventory-based machine/service configuration
- automatic secrets management (vars)
- deployment tooling

## machines

| machine       | type    | description                                          |
| ------------- | ------- | ---------------------------------------------------- |
| simon-desktop | desktop | daily driver workstation                             |
| lpt-titan     | laptop  | framework 13                                         |
| hm-nixbox     | server  | home server: monitoring, immich, paperless, openclaw |
| hzc-pango     | vps     | hetzner, reverse proxy (pangolin)                    |

IPs in `machines/flake-module.nix` under `inventory.machines` and `instances.internet`.

### ssh access

```bash
ssh <machine>.clan              # .clan tld (clan-core)
ssh <machine>.lan               # .lan tld (local network)
ssh root@<ip>                   # direct IP (from deploy output)
```

## repo structure

- `machines/` - per-host nixos configs
- `machines/flake-module.nix` - clan inventory, services, deploy targets
- `modules/` - reusable nixos modules under `nixfiles.*` namespace
- `modules/profiles/` - base profiles (server, workstation) applied via tags
- `users/` - home-manager configs per user
- `lib/` - mylib helpers
- `vars/` - clan-generated secrets/config per machine
- `docs/` - guides and rationale (why things are the way they are)

## principles

- **declarative first** - avoid manual changes, everything should be in nix config
- if something needs manual intervention, find a way to declare it instead
- **troubleshoot remotely** - don't ask user to check machines, ssh in and debug yourself
- **no deploy without permission** - never run `clan machines update` or deploy to machines without explicit user instruction
- **ATOMIC COMMITS** - one logical change per commit. NEVER bundle unrelated changes. use `jj split` to separate changes before committing.
  - one feature across multiple files = ONE commit (e.g., adding ldap group mapping to immich + grafana + authelia)
  - unrelated changes = separate commits
  - refactor + docs for that refactor = separate commits
- **run `nix fmt` before committing** - always format nix files

## patterns

- `mylib.scanPaths ./. { }` - auto-import all .nix files in directory
- **importing a module enables it** - NO `enable` options, NO `nixfiles.*.enable = true`. just import the module and it's on. exception: modules with submodules (like monitoring) where you import the parent but enable specific children
- some modules have prerequisites (e.g., lanzaboote needs `sbctl create-keys` on target before deploy)
- `lib.mkDefault` for overridable defaults in profiles
- `lib.mkForce` to override conflicting services
- flake input package overrides - patch external packages locally:

```nix
inputs.foo.packages.${system}.pkg.overrideAttrs (old: {
  # if installPhase is a script path, source it then add commands:
  installPhase = ''
    source ${old.installPhase}
    cp -r $src/extra $out/lib/pkg/
  '';
});
```

## clan-core

### commands

```bash
nh os switch                    # switch locally
clan machines update <machine>  # deploy remote (or local)
clan install                    # install new machine
clan vars generate              # generate missing vars
ssh root@<machine>.clan         # .clan is default tld from clan-core
```

### inventory

defined in `machines/flake-module.nix` - machines, services, deploy targets. self-documenting, just read the file.

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

generator pattern:

```nix
clan.core.vars.generators.myvar = {
  share = true;                        # shared across machines (vs per-machine)
  files."filename.ext".secret = false; # public file (not encrypted)
  files."secret.key" = { };            # encrypted by default
  script = "true";                     # no-op, manually populate files
};
```

access in modules: `config.clan.core.vars.generators.<name>.files."<file>".path`

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
nix log <store-path>            # view build log
nix-store -qR <path> | grep x   # find package in closure
```

## monitoring

metrics are stored in VictoriaMetrics on hm-nixbox. when looking for metrics, query there.

## notable services (hm-nixbox)

- **openclaw** (`modules/openclaw/`) - AI gateway, uses flake input override for docs bundling
- **immich** - photo management
- **paperless** - document management
- **authelia** - SSO/auth proxy
- **arr-stack** - media automation (sonarr, radarr, etc)

## persistence

all machines use preservation (opt-in state). root filesystem is ephemeral, only explicitly persisted paths survive reboot. see `docs/preservation.md` for details.

## home-manager

home-manager configs in `users/<user>/`. access nixos config via `osConfig`:

```nix
{ osConfig ? null, ... }:
let
  varPath = osConfig.clan.core.vars.generators.myvar.files."file".path or null;
in
{
  # use varPath...
}
```

## module categories

modules live in `modules/` with these categories:

| category    | modules                                                           |
| ----------- | ----------------------------------------------------------------- |
| hardware    | cpu/, gpu/, bcachefs/, zfs/, fprint/, yubikey/, lanzaboote/       |
| power       | power/ (tuned, ppd, auto-cpufreq, logind, upower)                 |
| persistence | persistence/ (impermanence, preservation, rollback)               |
| networking  | tailscale/, pangolin/                                             |
| services    | nginx/, acme/, authelia/, lldap/, k3s/, notify/, vert/            |
| monitoring  | monitoring/ (beszel, victoriametrics, telegraf, grafana, netdata) |
| media       | immich/, paperless/, arr-stack (in machine config)                |
| security    | vaultwarden/                                                      |
| ai          | openclaw/, ollama (in machine config)                             |
| desktop     | dms/, niri/, quickshell/, gaming/, virtualization/                |
| profiles    | profiles/base/, profiles/server/, profiles/workstation/           |

## module enable patterns

modules with submodules use enable options:

```nix
# monitoring - import parent, enable children
nixfiles.monitoring.beszel.hub.enable = true;
nixfiles.monitoring.telegraf.enable = true;

# gaming - import parent, enable children
nixfiles.gaming.steam.enable = true;
nixfiles.gaming.lutris.enable = true;

# virtualization
nixfiles.virtualization.docker.enable = true;
nixfiles.virtualization.podman.enable = true;

# power
nixfiles.power.tuned.enable = true;
nixfiles.power.logind.enable = true;
```

## known deprecations

| issue              | status           | action                                                              |
| ------------------ | ---------------- | ------------------------------------------------------------------- |
| nixos-generators   | deprecated 25.05 | migrate to `nixos-rebuild build-image` when convenient              |
| clanServices/admin | deprecated       | waiting for clan-core PR #6609, then migrate to sshd.authorizedKeys |

## service quirks

- **immich** - ML disabled (`modules/immich/default.nix:124`), Intel Arc GPU onnx compatibility issue
- **radicle** - checkConfig disabled, settings format needs fixing
- **zfs** - hostId in `modules/zfs/default.nix` must not change (breaks existing pools)
- **tuned** - has workaround for nixpkgs#463443 (ppd.conf bug)

## desktop shell

- `nixfiles.quickshell` - "dms", "noctalia", or "none"
- `nixfiles.machineType` - "desktop" or "laptop"
- dms: use `settings.json` directly, not nix attrset (simpler to maintain)
- way-displays: always takes control of scaling, no passthrough to niri

## vcs

jj (jujutsu) colocated with git. **ignore git internals** - jj handles everything, don't analyze git state.

```bash
jj status                       # current changes
jj log                          # history
jj commit -m "msg"              # describe + create new change
jj describe -m "msg"            # describe only, stay on same change
jj new                          # create new change on top
jj split -m "msg" -- <files>    # extract files into separate change
jj bookmark set main -r @       # move main bookmark
jj git push                     # push
```

workflow: commit working changes, continue on new change. bookmark + push only when ready.

## debugging

```bash
# build without deploying (catch errors early)
nix build .#nixosConfigurations.<machine>.config.system.build.toplevel

# evaluate specific option
nix eval .#nixosConfigurations.<machine>.config.<option> --json

# find what provides a file in the system closure
nix-store -qR /run/current-system | xargs -I{} sh -c 'ls {}/ 2>/dev/null | grep -q <file> && echo {}'

# view service logs
journalctl -u <service> -f

# check systemd service status
systemctl status <service>

# view nixos-rebuild output
nixos-rebuild build --flake . 2>&1 | head -100
```

## file structure conventions

- machine configs: `machines/<name>/` with `configuration.nix` as entry
- facter.json: hardware facts (auto-generated, don't edit)
- disko.nix: disk partitioning (used by clan install)
- home.nix: machine-specific home-manager overrides
