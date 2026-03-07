# claude code context

## overview

this repo is built on [clan-core](https://docs.clan.lol/) - a framework for managing nixos machines with:

- inventory-based machine/service configuration
- automatic secrets management (vars)
- deployment tooling

## machines

| machine       | type    | description                                                   |
| ------------- | ------- | ------------------------------------------------------------- |
| simon-desktop | desktop | daily driver workstation                                      |
| lpt-titan     | laptop  | framework 13 (lanzaboote, fprint, bcachefs)                   |
| hm-nixbox     | server  | home server: apps, monitoring, nix cache, backups             |
| hzc-pango     | vps     | hetzner: netbird server, wireguard controller, monitoring hub |
| clawbox       | server  | local AI box (openclaw, signal-cli)                           |

IPs in `machines/flake-module.nix` under `inventory.machines` and `instances.internet`.

### per-machine module imports

know what each machine uses to avoid building/evaluating wrong targets.

- **simon-desktop**: gaming, yubikey, power, gpu, cpu, virtualization, dms, niri, persistence
- **lpt-titan**: nixos-hardware.framework-amd-ai-300-series, yubikey, power, gpu, cpu, lanzaboote, fprint, bcachefs, dms, niri, persistence
- **hm-nixbox**: acme, arr-stack, borgbackup, nginx, filebrowser-quantum, nextcloud, lldap, authelia, immich, paperless, vaultwarden, stirling-pdf, zfs, gpu, cpu, power, persistence, hd-idle, notify, virtualization, vert + scanPaths (excludes: dashboards, radicle.nix)
- **hzc-pango**: srvos.hardware-hetzner-cloud, borgbackup, power, persistence + scanPaths (excludes: pangolin.nix, crowdsec.nix, monitoring.nix)
- **clawbox**: power, persistence + scanPaths (openclaw.nix, signal-cli.nix, networking.nix via scan)

### ssh access

```bash
ssh <machine>.s                 # clan meta domain (yggdrasil mesh)
ssh <machine>.lan               # .lan tld (local network)
ssh root@<ip>                   # direct IP (from deploy output)
```

### networking

- **yggdrasil** — mesh network, provides `.s` domain resolution between all machines
- **netbird** — mesh vpn, server on hzc-pango (`nb.fosskar.eu`), all machines are clients
- **wireguard** — site-to-site, controller on hzc-pango

## repo structure

- `machines/` - per-host nixos configs
- `machines/flake-module.nix` - clan inventory, services, deploy targets
- `modules/` - reusable nixos modules under `nixfiles.*` namespace
- `modules/profiles/` - base profiles (server, workstation) applied via tags
- `users/` - home-manager configs per user (only `users/simon/`)
- `lib/` - mylib helpers (`scanPaths`, `scanFlakeModules`)
- `vars/` - clan-generated secrets/config per machine
- `docs/` - guides (preservation.md, secureboot.md, tangled.md, gpg-yubikey.md)

## principles

- **declarative first** - avoid manual changes, everything should be in nix config
- if something needs manual intervention, find a way to declare it instead
- **troubleshoot remotely** - don't ask user to check machines, ssh in and debug yourself
- **no destructive actions without explicit permission** - never run `clan machines update`, `reboot`, `systemctl restart`, or any destructive command without explicit user instruction. if user says "i would restart now?" that's a QUESTION seeking confirmation, not an instruction. "check it please" means check AFTER user does it, not do it yourself. when in doubt, ask.
- **ATOMIC COMMITS** - one logical change per commit. NEVER bundle unrelated changes. use `jj split` to separate changes before committing.
  - one feature across multiple files = ONE commit (e.g., a single auth/role-mapping change across related services)
  - unrelated changes = separate commits
  - refactor + docs for that refactor = separate commits
- **prefer minimal fixes first** - default to the simplest direct fix for current config/runtime. only introduce compatibility layers or broader refactors when explicitly requested.
- **prefer the simplest valid command flow** - avoid over-engineered command sequences when a shorter equivalent exists.
- **be explicit, not abstract** - when debugging conflicts, state exactly who sets the option, where, and to what value.
- **communicate continuously while working** - send short progress updates during exploration, edits, and verification (what is being checked/changed and why), not only final results.
- **prioritize WHY over WHAT** - user can read the code for implementation details; always explain the reasoning, intent, and tradeoffs behind changes first.
- **run `nix fmt` before committing** - always format nix files

## patterns

- `mylib.scanPaths ./. { }` - auto-import all .nix files in directory (exclude with `{ exclude = [ "file.nix" ]; }`)
- `mylib.scanFlakeModules ./.` - auto-discover `flake-module.nix` files across repo
- **importing a module enables it** - NO `enable` options, NO `nixfiles.*.enable = true`. just import the module and it's on. exception: modules with submodules (like monitoring) where you import the parent but enable specific children
- some modules require one-time host prerequisites before deploy (e.g., lanzaboote key provisioning with `sbctl create-keys`)
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
ssh root@<machine>.s            # from clan.meta.domain = "s"
```

### inventory

defined in `machines/flake-module.nix` - machines, services, deploy targets. self-documenting, just read the file.

### tags

- `server` → `modules/profiles/server`
- `desktop`, `laptop`, `workstation` → `modules/profiles/workstation`
- `home`, `hetzner` - location grouping
- `ai` - AI machines (clawbox)
- `all` - all machines (used by sshd, clan-cache, yggdrasil, netbird client)

### clan services in use

| service            | module    | purpose                                              |
| ------------------ | --------- | ---------------------------------------------------- |
| emergency-access   | clan-core | emergency access for all nixos machines              |
| sshd               | clan-core | authorized keys + ssh certificates                   |
| root-user          | clan-core | root user on workstations (users module)             |
| simon-user         | clan-core | simon user on desktop+laptop (users module)          |
| clan-cache         | clan-core | trusted nix caches                                   |
| yggdrasil          | (builtin) | mesh networking                                      |
| internet           | (builtin) | IP exports for yggdrasil peering                     |
| syncthing          | clan-core | folder sync (desktop ↔ laptop)                      |
| borgbackup         | clan-core | backups to hetzner storagebox (hm-nixbox, hzc-pango) |
| wifi               | clan-core | declarative wifi profiles (lpt-titan only)           |
| ncps               | clan-core | nix cache proxy (server: hm-nixbox, clients: rest)   |
| netbird            | self      | mesh vpn (server: hzc-pango, all clients)            |
| wireguard          | clan-core | site-to-site (controller: hzc-pango)                 |
| server-module      | importer  | applies server profile via tag                       |
| workstation-module | importer  | applies workstation profile via tag                  |

### vars

- `vars/per-machine/<machine>/` - machine-specific generated secrets
- `vars/shared/` - shared across machines
- auto-generated: syncthing keys, borgbackup keys, passwords, ssh keys, etc
- encrypted with sops (age + yubikey)

generator naming: **`service` as generator name, secrets as file names** — `generators.myservice.files."my-secret"`, NOT `generators.myservice-my-secret.files."my-secret"`.

generator pattern:

```nix
clan.core.vars.generators.myservice = {
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

## module categories

modules live in `modules/` with these categories:

| category       | modules                                                                                                              |
| -------------- | -------------------------------------------------------------------------------------------------------------------- |
| hardware       | cpu/, gpu/, bcachefs/, zfs/, fprint/, yubikey/, lanzaboote/                                                          |
| power          | power/ (tuned, ppd, auto-cpufreq, logind, upower, powertop)                                                          |
| persistence    | persistence/ (preservation, fs-specific persistence helpers)                                                         |
| networking     | netbird/, tailscale/, pangolin/                                                                                      |
| infra/services | nginx/, acme/, authelia/, lldap/, kanidm/, k3s/, notify/, vert/, borgbackup/, hd-idle/                               |
| monitoring     | monitoring/ (beszel, victoriametrics, victorialogs, telegraf, grafana, netdata, exporter)                            |
| apps           | immich/, paperless/, vaultwarden/, nextcloud/, openclaw/, it-tools/, stirling-pdf/, filebrowser-quantum/, arr-stack/ |
| desktop        | dms/, niri/, gaming/, virtualization/                                                                                |
| profiles       | profiles/server/, profiles/workstation/                                                                              |

note: some modules exist but are not actively imported by any machine (kanidm, k3s, it-tools, tailscale, pangolin). they're available but unused.

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

## module formatting convention

all modules follow a consistent internal structure with lightweight section comments.

### let preamble order

```nix
let
  cfg = config.nixfiles.<name>;
  acmeDomain = config.nixfiles.acme.domain;        # if web service
  inherit (config.nixfiles.authelia) publicDomain;  # if uses oidc
  serviceDomain = "<sub>.${acmeDomain}";            # if web service
  port = <number>;                                  # if defines a port
  # module-specific bindings...
in
```

### section order (only include sections that exist)

```nix
{
  # --- options ---
  options.nixfiles.<name> = { ... };

  config = lib.mkIf cfg.enable {
    # --- secrets ---        # clan.core.vars.generators
    # --- oidc ---           # authelia client registration
    # --- service ---        # main service config, users/groups
    # --- nginx ---          # nixfiles.nginx.vhosts or manual vhost
    # --- backup ---         # clan.core.state, clan.core.postgresql
    # --- persistence ---    # nixfiles.persistence.directories
    # --- systemd ---        # systemd overrides, tmpfiles, extra packages
  };
}
```

for non-web modules (hardware, desktop, infra), use `# --- options ---`, `# --- config ---`, or `# --- service ---` as appropriate. skip section comments in tiny files (<15 lines of config).

## persistence

all machines use preservation (opt-in state). root filesystem is ephemeral, only explicitly persisted paths survive reboot. see `docs/preservation.md` for details.

## home-manager

home-manager configs in `users/simon/` with categories: browsers/, cli/, desktop/, editors/, media/, shell/, system/, terminals/.

options defined in `users/simon/default.nix`:

- `nixfiles.machineType` - "desktop" or "laptop" (set per-machine in `machines/<name>/home/default.nix`)
- `nixfiles.quickshell` - "dms", "noctalia", or "none" (default: "noctalia")

access nixos config via `osConfig`:

```nix
{ osConfig ? null, ... }:
let
  varPath = osConfig.clan.core.vars.generators.myvar.files."file".path or null;
in
{
  # use varPath...
}
```

## desktop shell

- niri (wayland compositor) + quickshell-based shell (dms or noctalia)
- dms: use `settings.json` directly, not nix attrset (simpler to maintain)
- way-displays: always takes control of scaling, no passthrough to niri
- both simon-desktop and lpt-titan use dms + niri

## known deprecations / volatile status

keep this section short. if it grows, move details to a dedicated doc under `docs/` and link from here.

| issue              | status           | action                                                 |
| ------------------ | ---------------- | ------------------------------------------------------ |
| nixos-generators   | deprecated 25.05 | migrate to `nixos-rebuild build-image` when convenient |
| clanServices/admin | removed          | migrated to `sshd.authorizedKeys`                      |

## service quirks

- **immich** - ML uses local package/runtime overrides (`modules/immich/default.nix`); verify compatibility after nixpkgs or immich updates
- **grafana** - needs `groups` in id_token (not just userinfo) for role mapping
- **radicle** - checkConfig disabled, settings format needs fixing (excluded from hm-nixbox scanPaths)
- **zfs** - for zfs machines, keep `networking.hostId` stable per machine (in each machine's networking config)
- **tuned** - has workaround for nixpkgs#463443 (ppd.conf bug)
- **nix-citizen** - don't follow nixpkgs; wine-astral needs old wine/base.nix API (pinned in flake.nix)
- **openclaw** - AI gateway with hardlinked plugin manifest workaround; uses llm-agents flake input

## vcs

jj (jujutsu) colocated with git. **ignore git internals** - jj handles everything, don't analyze git state.

**NEVER run `jj restore` or `git restore` or `git checkout -- <file>`** - these discard ALL uncommitted changes, not just the last edit. to undo a specific change, use the Edit tool to manually revert that change only.

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

when user says **"commit and push"**:

- include **all current working-copy changes** in repo (unless user explicitly scopes files)
- split into **atomic commits** by logical change
- use the **simplest jj flow** that moves `main` to the intended commit and pushes it
- do **not** ask for reconfirmation on explicit imperative commands; execute directly
- avoid unnecessary command complexity; if scope is ambiguous, ask once before pushing

codex/sandbox note:

- keep commit signing enabled; do not disable `git.sign-on-push` (globally, locally, or per-command override)
- when `jj git push` fails in sandbox due to signing key or network/socket access, rerun the same `jj git push` with escalation instead of changing signing behavior

## agent operating playbook

use this as the default execution order to reduce misses and backtracking.

1. scope first (always)
   - `jj status`
   - `jj diff --stat`
   - `rg "<option|service|module>" machines modules users`

2. change minimally
   - edit the smallest surface that can fix the issue
   - prefer direct fixes over abstractions/compat layers unless explicitly requested

3. verify proportionally — **don't always full-build**
   - docs/text-only changes: no verification needed
   - simple value changes (strings, URLs, ports, settings in existing options): `nix eval` on the specific option is enough
   - structural changes (new modules, new packages/extensions, option type changes, new imports): full `nix build .#nixosConfigurations.<machine>.config.system.build.toplevel`
   - uncertain behavior/merge semantics: verify with `nix eval` on the exact option

4. communicate in phases
   - short updates during: exploration → edit → verification → commit/push
   - always state why this next step is being run

5. finalize with simplest valid flow
   - for "commit and push": include full requested scope, split atomically, then:
     - `jj bookmark set main -r @`
     - `jj git push`

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
- home-manager machine overrides: `machines/<name>/home/default.nix`
- extra machine-local configs via scanPaths (e.g., monitoring.nix, networking.nix, samba.nix)

## pre-finish checklist

- run `nix fmt` after nix edits
- run targeted `nix build .#nixosConfigurations.<machine>.config.system.build.toplevel` for touched machines
- use `nix eval` for changed options when behavior is unclear
- add newly created files to vcs tracking before finish (`jj file track <path>`)
- do not deploy/restart/update remotely unless user explicitly asked
