# nixfiles agent playbook

purpose: help agents work fast + correctly in this repo without stale assumptions.

## 0) hard rules

- declarative first. no manual drift.
- no destructive remote actions unless user explicitly says so.
  - do not run: `clan machines update`, `reboot`, `systemctl restart`, destructive migrations.
- atomic commits only.
- prefer minimal direct fix over abstractions.
- do not introduce unnecessary `let ... in` bindings or other local abstractions for single-use values.
- avoid Nix `with` expressions; prefer explicit attribute references.
- existing text/pattern is evidence, not justification; keep it only if it still serves current repo/task.
- explain why, not code-tour.
- no guessing/hedging in responses (`likely`, `maybe`, `probably`). verify with evidence or state unknown.
- for external claims: verify in source, cite path, else say unknown.
- run `nix fmt` after nix edits.

## 1) initial repo check

run before non-trivial repo changes:

```bash
jj status
jj diff --stat
rg "imports|scanPaths|self\.modules|config\.flake\.modules" machines modules clanServices users
rg "inventory =|instances =|roles\.|tags\." machines/flake-module.nix
```

if task touches option/service/module:

```bash
rg "<option|service|module|domain>" machines modules clanServices users docs
```

do not run clan/deploy/network commands as default orientation. use them only when task explicitly touches clan inventory, vars, deployment, or runtime networking; prefer local `rg`/`nix eval` first.

## 2) core concepts

### dendritic / flake-parts module model

repo uses dendritic-style composition: feature modules export aspect modules through `flake.modules.*`; machines and clan roles select those aspects through imports.

- feature module: flake-parts module that defines one or more `flake.modules.*` entries and any related flake wiring.
- aspect module: module for one configuration class, e.g. `flake.modules.nixos.<name>`, `flake.modules.homeManager.<name>`, `flake.modules.generic.<name>`.
- simple aspect: independent aspect imported directly where needed.
- multi-context aspect: main aspect also wires a nested context, e.g. a nixos aspect importing/wiring home-manager.
- inheritance aspect: aspect imports parent aspects, then extends or overrides them.
- conditional aspect: aspect content is conditional; imports stay unconditional.
- collector aspect: one aspect collects contributions from other feature modules. this is distinct from a broad role/profile feature.
- feature-owned integration: service/app-specific glue lives in the feature module that needs it, not in the module it integrates with.
- composition edge: place that chooses aspects for a concrete target, mainly host imports and clan role imports.
- import is the primary enable mechanism; do not add `nixfiles.*` wrapper options unless current code already defines them.
- make feature modules self-contained: if a feature needs homepage entries, gatus checks, reverse proxy routes, desktop shortcuts, window rules, or related glue, define that glue in the feature module and guard it on the integrated service being enabled when needed.

### repo mapping

- `modules/{nixos,home,generic}/`: feature modules and aspect definitions.
- `machines/<machine>/configuration.nix`: host composition edge.
- `machines/flake-module.nix`: clan inventory plus role composition edge.
- `clanServices/`: clan service feature modules and role wiring.
- `users/simon/`: home-manager user composition.
- `openwrt/`: declarative openwrt config for router and ap (uci via `openwrt/nix/uci.nix`, raw config files under `openwrt/devices/<device>/files/`). the lan router (192.168.10.1) runs unbound (caching resolver for the whole lan, split-horizon for nx3.eu) and adguardhome; its config lives here, not on the device. dns/network tasks must check `openwrt/devices/router/` before suggesting resolver or firewall changes.

### clan model

clan owns machine inventory, tags, secrets/vars, and service role assignment. host files own host-local composition and hardware/storage details.

- inventory and tags decide which clan roles apply to which machines.
- clan `instances` wire roles to machines/tags and can inject extra nixos modules.
- `clanServices/` defines reusable clan service modules, role modules, peer wiring, and vars.
- secrets should use `clan.core.vars.generators` when possible.
- deployment/runtime clan commands are not discovery commands; prefer reading/evaluating local nix first.

## 3) investigation rules

agents know their tools; this section defines what must be proven before editing.

- before changing a module, prove where its aspect is exported, where it is imported, and whether multiple files contribute to the same aspect.
- before changing a machine, inspect host imports plus files included by `scanPaths`.
- before changing clan behavior, inspect inventory instance, role settings, target tags/machines, and related `clanServices` module.
- before changing service/front-door behavior, inspect service module plus reverse proxy vhost/route definitions.
- before changing persistence, inspect `preservation.preserveAt."/persist"` users and rollback module.
- prefer local repo search/eval for discovery. use clan/runtime/network commands only when task needs runtime state or user explicitly asks.

## 5) machines and access

machine ids are source-of-truth in `machines/flake-module.nix`; do not hardcode a list here.

discover:

```bash
nix eval .#clan.inventory.machines --json | jq 'keys'
fd -td -d1 . machines
```

ssh patterns:

```bash
ssh <machine>.s
ssh <machine>.lan
ssh root@<ip>
```

## 6) task routing cheatsheet

- change service behavior globally:
  - edit/export relevant `modules/nixos/services/<service>.nix` or submodule
  - verify host/clan imports using `rg "self.modules.nixos.<name>|config.flake.modules.nixos.<name>"`
- change one host:
  - edit `machines/<host>/configuration.nix` or host-local file loaded via `scanPaths`
- change common role behavior:
  - edit aggregate module in `modules/nixos/common/{base,server,workstation}/`
  - verify clan importer roles in `machines/flake-module.nix`
- change clan role assignment/service ownership:
  - edit instance block in `machines/flake-module.nix`
- change clan service implementation:
  - edit `clanServices/<service>/default.nix`
  - edit `clanServices/<service>/flake-module.nix` for service module wiring
- debug option conflict:
  - `rg` all setters, then `nix eval` exact option
- add reusable module:
  - create under matching aspect tree in `modules/`
  - export through `flake.modules.<class>.<name>`
  - import it from machine/clan composition edge; import means enabled unless module defines its own `enable`

## 7) module patterns

- `mylib.scanPaths ./. { }` auto-imports directory nix files.
- `mylib.scanFlakeModules ./.` auto-discovers `flake-module.nix` files.
- module files under `modules/` usually assign `flake.modules.<class>.<name> = ...`.
- same exported module name can be extended by multiple files; grep all definitions before editing collectors like `base`, `server`, `workstation`, `gaming`, `arrStack`, `homepage`.
- default rule: import => enabled.
- exception: modules with explicit `enable` options or upstream services still need those options.
- prefer upstream option namespaces (`services.*`, `programs.*`, `users.*`, `preservation.*`, `clan.core.*`) over repo-specific wrappers.

override tools:

- `lib.mkDefault` for soft defaults
- `lib.mkForce` for real conflicts only
- avoid adding new options unless user asked; hardcode sane defaults first

## 8) vars/secrets

- prefer clan vars generators for service secrets.
- generator naming rule:
  - generator name = service
  - file name = secret/env filename
  - use `clan.core.vars.generators.<service>.files."<file>"`
- manual secret path only when already in use for that service.

example:

```nix
clan.core.vars.generators.myservice = {
  share = true;
  files."filename.ext".secret = false;
  files."secret.key" = { };
  script = "true";
};
```

## 9) verify proportionally

- docs/text only: no build.
- simple value change in existing option: `nix eval` target option.
- structural/module/import/package changes: build touched machine(s).

commands:

```bash
nix eval .#nixosConfigurations.<machine>.config.<option> --json
nix build .#nixosConfigurations.<machine>.config.system.build.toplevel
```

## 10) debugging quick cmds

```bash
journalctl -u <service> -f
systemctl status <service>
nix log <store-path>
```

## 11) vcs

use jj, not git porcelain.

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

- include full working copy scope unless user narrows.
- split atomically by logical change.
- move `main` then push.
- do not reconfirm explicit imperative command.

## 12) nix/dev env notes

- prefer flake-native commands (`nix build`, `nix shell`, `nix develop`).
- temporary tool: `nix shell nixpkgs#<pkg>`.
- format nix: `nix fmt`.

## 13) sharp edges / quirks

- preservation: root is ephemeral; persist explicit dirs/files only (`docs/preservation.md`).
- first install with preservation disabled; enable after secrets have landed (`machines/README.md`).
- zfs machines: keep `networking.hostId` stable.
- grafana oidc role mapping needs `groups` in `id_token`.
- tuned has nixpkgs bug workaround (`ppd.conf` issue).
- netbird is custom module set in this repo.
- netbird reverse proxy has two modes: permanent dashboard/API peer targets need service reachable on peer NetBird interface (bind `0.0.0.0` or NetBird IP); `netbird expose` can expose local `127.0.0.1` services through peer-created ephemeral tunnel.
- remote-builder: `sshUser = "nix"` needs real shell on builder; nologin breaks `ssh-ng`.
- remote-builder proof cmd: `nix build nixpkgs#hello --no-link --option substitute false --max-jobs 0 -L`.
- harmonia option path is `services.harmonia.cache.*`.
- do not force `--build-host localhost` in shell wrappers.

## 14) pre-finish checklist

- `nix fmt` after nix edits.
- verify proportionally.
- track newly created files if any (`jj file track <path>`).
- do not deploy/restart/update remote machines unless explicitly asked.
