# nixfiles agent playbook

purpose: help the agent work fast + correctly in this repo without stale assumptions.

## 0) hard rules

- declarative first. no manual drift.
- no destructive remote actions unless user explicitly says so.
  - do not run: `clan machines update`, `reboot`, `systemctl restart`, destructive migrations.
- atomic commits only.
- prefer minimal direct fix over abstractions.
- explain why, not code-tour.
- no guessing/hedging in responses (`likely`, `maybe`, `probably`). verify with evidence or state unknown.
- for external claims: verify in source, cite path, else say unknown.
- run `nix fmt` after nix edits.

## 1) first 60s loop (always)

```bash
jj status
jj diff --stat
rg "imports|scanPaths" machines
rg "inventory =|instances =|roles\\.|tags\\." machines/flake-module.nix
```

if task touches option/service:

```bash
rg "<option|service|module>" machines modules users
```

## 2) source-of-truth index (volatile stuff)

never trust memory for these.

- machine wiring, tags, clan instances, role ownership:
  - `machines/flake-module.nix`
- what a machine actually runs:
  - `machines/<machine>/configuration.nix`
  - plus files pulled by `mylib.scanPaths` in that machine dir
- networking topology/endpoints:
  - `machines/flake-module.nix` (`instances.internet`, networking instances)
  - `modules/networking/` + machine-local networking files
- reverse proxy/front door:
  - `modules/caddy/`, `modules/nginx/`, `modules/traefik/`
  - then check imports per machine
- home-manager behavior:
  - `users/simon/`
  - `machines/<machine>/home/default.nix`
- vars/secrets shape:
  - `vars/`
  - generator defs in modules
  - `machines/flake-module.nix`

## 3) repo map

- `machines/` per-host nixos config
- `machines/flake-module.nix` clan inventory + service wiring + deploy metadata
- `modules/` reusable nixos modules (`nixfiles.*` namespace)
- `modules/profiles/` base profile modules by tag
- `users/simon/` home-manager config
- `lib/` helpers (`scanPaths`, `scanFlakeModules`)
- `vars/` clan vars (generated, encrypted where needed)

## 4) machine list (stable ids)

- `simon-desktop`
- `lpt-titan`
- `nixbox`
- `gateway`
- `crowbox`

ssh patterns:

```bash
ssh <machine>.s
ssh <machine>.lan
ssh root@<ip>
```

## 5) task routing cheatsheet

- change service behavior globally:
  - edit `modules/<service>/...`
  - verify machines importing it
- change only one host:
  - edit `machines/<host>/configuration.nix` or host-local file loaded via scanpaths
- change clan role assignment/service ownership:
  - edit instance block in `machines/flake-module.nix`
- debug option conflict:
  - `rg` all setters, then `nix eval` exact option
- add module tree-wide:
  - import module where needed (import means enabled unless submodule pattern)

## 6) module patterns

- `mylib.scanPaths ./. { }` auto imports directory nix files
- `mylib.scanFlakeModules ./.` auto discovers `flake-module.nix`
- default rule: import => enabled
- exception: modules with submodules use `enable` flags on children

examples:

```nix
nixfiles.monitoring.telegraf.enable = true;
nixfiles.gaming.steam.enable = true;
nixfiles.virtualization.docker.enable = true;
```

override tools:

- `lib.mkDefault` for soft defaults
- `lib.mkForce` for conflicts
- avoid adding new options unless user asked; hardcode sane defaults first

## 7) vars/secrets

- prefer clan vars generators for service secrets
- manual secret path: `sops.secrets."<name>"`
- generator naming rule:
  - generator name = service
  - file name = secret
  - use `generators.<service>.files."<file>"`

template:

```nix
clan.core.vars.generators.myservice = {
  share = true;
  files."filename.ext".secret = false;
  files."secret.key" = { };
  script = "true";
};
```

## 8) verify proportionally

- docs/text only: no build
- simple value change in existing option: `nix eval` target option
- structural/module/import/package changes: build touched machine(s)

commands:

```bash
nix eval .#nixosConfigurations.<machine>.config.<option> --json
nix build .#nixosConfigurations.<machine>.config.system.build.toplevel
```

## 9) debugging quick cmds

```bash
journalctl -u <service> -f
systemctl status <service>
nix log <store-path>
```

## 10) vcs (jj only)

ignore git internals. use jj.

never run:

- `jj restore`
- `git restore`
- `git checkout -- <file>`

use:

```bash
jj status
jj log
jj commit -m "msg"
jj describe -m "msg"
jj new
jj split -m "msg" -- <files>
jj bookmark set main -r @
jj git push
```

if user says "commit and push":

- include full working copy scope unless user narrows
- split atomically by logical change
- move `main` then push
- do not reconfirm explicit imperative command

## 11) nix/dev env notes

- prefer flake-native commands (`nix build`, `nix shell`, `nix develop`)
- temporary tool: `nix shell nixpkgs#<pkg>`
- format nix: `nix fmt`

## 12) sharp edges / quirks (worth remembering)

- persistence: root is ephemeral; persist explicit dirs only (`docs/preservation.md`)
- zfs machines: keep `networking.hostId` stable
- immich: ml/runtime overrides in module; recheck on nixpkgs/immich bumps
- grafana oidc role mapping needs `groups` in `id_token`
- tuned has nixpkgs bug workaround (`ppd.conf` issue)
- netbird is custom module set in this repo
- netbird reverse proxy has two modes: permanent dashboard/API peer targets need the service reachable on the peer's NetBird interface (bind `0.0.0.0` or NetBird IP), while `netbird expose` can expose local `127.0.0.1` services through a peer-created ephemeral tunnel
- remote-builder: `sshUser = "nix"` needs a real shell on builder (nologin breaks `ssh-ng`)
- remote-builder proof cmd: `nix build nixpkgs#hello --no-link --option substitute false --max-jobs 0 -L`
- harmonia option path is `services.harmonia.cache.*` (old `services.harmonia.*` is renamed)
- do not force `--build-host localhost` in shell wrappers

## 13) pre-finish checklist

- `nix fmt`
- verify proportionally (eval/build based on change type)
- track newly created files if any (`jj file track <path>`)
- do not deploy/restart/update remote machines unless explicitly asked
