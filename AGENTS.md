# nixfiles agent playbook

## hard rules

- declarative first; no manual drift
- no destructive remote actions unless explicit
- do not run by default: `clan machines update`, `reboot`, `systemctl restart`, destructive migrations
- atomic commits only
- prefer minimal direct fix over abstractions
- no unnecessary single-use `let ... in` or local abstractions
- avoid Nix `with`; use explicit attrs
- existing text/pattern is evidence, not justification; keep only if it serves current repo/task
- unused/unimported modules are NOT dead code; they are a library of ready-to-enable aspects — never delete or propose deleting a module just because nothing currently imports it
- explain why, not code tours
- code comments: code is self-explanatory, especially nix. default zero comments. NEVER describe the WHAT; only non-obvious WHY/ref/FIXME/gotcha. never annotate one-line changes or single option settings. no headers, tours, restatement, or comments bulkier than code
- no guessing/hedging; verify or say unknown
- external claims: verify in source and cite path, else say unknown
- `nix fmt` after nix edits

## output

Chat replies: smart caveman. Artifacts use normal English unless requested: code, comments, docs, issues, PR/MR text, commits, email.

- drop articles, filler, pleasantries
- no hedging; verify or say unknown
- fragments ok; short synonyms
- exact: technical terms, identifiers, paths, commands, config, errors
- pattern: `[thing] [action] [reason]. [next step]`
- expand for safety, destructive confirmations, multi-step instructions, nontrivial reasoning, clarification

## initial checks

Before nontrivial repo changes:

```bash
jj status
jj diff --stat
rg "imports|scanPaths|self\.modules|config\.flake\.modules" machines modules clan-services users
rg "inventory =|instances =|roles\.|tags\." machines/flake-module.nix
```

If task touches option/service/module:

```bash
rg "<option|service|module|domain>" machines modules clan-services users docs
```

Do not use clan/deploy/network commands for discovery. Use only when task explicitly touches clan inventory, vars, deployment, or runtime networking. Prefer local `rg`/`nix eval`.

## model

- feature module: flake-parts module exporting `flake.modules.*` and related wiring
- aspect module: module for one class, e.g. `flake.modules.nixos.<name>`, `flake.modules.homeManager.<name>`
- simple aspect: imported directly
- multi-context aspect: main aspect wires nested context, e.g. nixos + home-manager
- inheritance aspect: imports parent aspects, then extends/overrides
- conditional aspect: conditional content; unconditional imports
- collector aspect: collects contributions from other feature modules; not broad role/profile
- feature-owned integration: service/app glue lives in feature module needing it
- composition edge: machine/clan role imports choosing aspects for concrete target
- import is primary enable mechanism
- feature modules should own homepage, gatus, reverse proxy, desktop shortcuts, window rules, and related glue; guard on integrated service when needed

## repo map

- `modules/{nixos,home-manager}/`: feature/aspect modules
- `modules/flake-parts/`: flake-level wiring/data, not feature modules; e.g. `flake.domains`, `flake.lib`, `flake.hosts` (`hosts.nix`, single source of machine IPs), `systems`, treefmt, devshells, packages, overlays, effects; `clan.nix` registers `clan-services/<svc>` as `clan.modules.<svc>`; auto-loaded by `import-tree ./modules`
- `machines/<machine>/configuration.nix`: host composition edge
- `machines/flake-module.nix`: clan inventory and role composition edge
- `clan-services/<svc>/default.nix`: clan.service modules (plain dir, referenced by `modules/flake-parts/clan.nix`, not auto-imported)
- `users/<user>/`: home-manager user composition (`simon`, `workspace`)
- `modules/home-manager/llm/`: agent tooling; `skills/<name>/` (dir per skill, `SKILL.md` + optional siblings) and `extensions/*.ts` auto-installed into all agent dirs by home-manager; deploy = rebuild/switch
- `openwrt/`: declarative router/ap config; uci via `openwrt/nix/uci.nix`, raw config under `openwrt/devices/<device>/files/`; lan router `192.168.10.1` runs unbound, split-horizon for `nx3.eu`, and adguardhome; config lives here, not on device
- supporting dirs: `docs/` (decisions, netbird-exposure, topology), `images/` (live-iso, vm-base), `overlays/`, `lib/` (`scanPaths`), `sops/`, `templates/` (project scaffolds), `.archive/` (deprecated services)

## clan

Clan owns inventory, tags, secrets/vars, and service role assignment. Host files own host-local composition and hardware/storage.

- inventory/tags decide role targets
- `instances` wire roles to machines/tags and can inject nixos modules
- `clan-services/` defines reusable service modules, roles, peer wiring, vars
- prefer `clan.core.vars.generators` for secrets
- deployment/runtime clan commands are not discovery commands

## investigation

- module edit: prove export, importers, duplicate contributors
- machine edit: inspect host imports and files loaded by `scanPaths`
- clan behavior: inspect inventory instance, role settings, target tags/machines, related `clan-services`
- service/front-door: inspect service module and reverse proxy vhost/routes
- persistence: inspect `preservation.preserveAt."/persist"` users and rollback module
- prefer local search/eval; runtime commands only when needed or requested

## machines

Machine ids source: `machines/flake-module.nix`.

Discover:

```bash
nix eval .#clan.inventory.machines --json | jq 'keys'
fd -td -d1 . machines
```

SSH: machine in clan inventory => prefer `clan ssh <machine>`; raw `ssh` fine for non-clan hosts.

```bash
clan ssh <machine>
# remote command: -c takes an argv list, not one shell string; pipelines need sh -c
clan ssh <machine> -c sh -c "journalctl -b --no-pager | tail -20"
```

## task routing

- global service behavior: edit/export `modules/nixos/services/<service>.nix` (multi-file services are dirs: `<service>/*.nix`, e.g. `arr-stack/`, `matrix/`, `opencloud/`); verify importers with `rg "self.modules.nixos.<name>|config.flake.modules.nixos.<name>"`
- one host: edit `machines/<host>/configuration.nix` or scanned host-local file
- common role: edit `modules/nixos/common/{base,server,workstation,laptop}/`; verify clan roles in `machines/flake-module.nix`
- clan role assignment/ownership: edit `machines/flake-module.nix`
- clan service implementation: edit `clan-services/<service>/default.nix`; registration is automatic via `modules/flake-parts/clan.nix`
- dashboard/monitoring/reverse proxy: use default options in service module; see service exposure
- option conflict: `rg` setters, then `nix eval` exact option
- reusable module: create under matching `modules/` tree; export `flake.modules.<class>.<name>`; import at composition edge
- local package: `packages/<name>/package.nix`; available as flake package `<name>` and `pkgs.local.<name>`; x86-only add to `x86OnlyPackages` in `modules/flake-parts/treefmt.nix`
- flake-level data: `modules/flake-parts/`

## module patterns

- `modules/` auto-imported by `import-tree`; `_` prefix excludes
- `nflib.scanPaths ./. { }` auto-imports directory nix files where called; no `_` convention
- module files usually assign `flake.modules.<class>.<name>`
- same exported module can have multiple contributors; grep before editing collectors (`base`, `server`, `workstation`, `gaming`, `arrStack`, `homepage`)
- default: import => enabled
- exception: explicit `enable` options or upstream services
- prefer upstream namespaces: `services.*`, `programs.*`, `users.*`, `preservation.*`, `clan.core.*`
- overrides: `lib.mkDefault` for defaults; `lib.mkForce` only for real conflicts
- avoid new options unless asked; hardcode sane defaults first

## service exposure

Services declare dashboard, health check, and reverse proxy with default options. No custom registry option (a `nixfiles.webServices` abstraction was tried and rejected 2026-07: per-module hand-written stanzas preferred over option indirection — do not re-suggest). Cross-host collectors pull remote homepage `services`/gatus `endpoints` into homepage/gatus host.

Dashboard:

```nix
services.homepage-dashboard.services = [ { "<group>" = [ { "<Name>" = { href; icon; siteMonitor; }; } ]; } ];
```

Rules:

- `services` is the stock nixpkgs option, available on every host, so non-homepage hosts can author tiles; the homepage module merges same-named groups at read-time (`services/homepage/homepage.nix` apply)
- do not guard dashboard tiles with `mkIf config.services.homepage-dashboard.enable` on non-homepage hosts
- gatus: `services.gatus.settings.endpoints = [ { name; url; group; enabled = true; alerts = [ { type = "email"; } ]; interval = "5m"; conditions = [ "[STATUS] == 200" ]; } ];`
- do not guard gatus endpoints with `mkIf config.services.gatus.enable` on non-gatus hosts
- local reverse proxy only: `services.caddy.virtualHosts.<host>.extraConfig`
- collectors: `modules/nixos/services/{homepage,gatus}/collector.nix`; exclude self to avoid recursion
- service on machine A appears on machine B homepage/gatus by setting default options on A
- caddy has no cross-host collector
- service-specific secret wiring stays in service module
- public `*.fosskar.eu` ingress = netbird-proxy on `gateway` (fronted by traefik TCP passthrough, `HostSNI(*)`), configured in the netbird UI (not declarative); a service maps a domain to a `{peer,protocol,port}` target, straight to peer:appPort (no caddy hop); exposed modules must bind `0.0.0.0`/wt0, not loopback, and keep the LAN closed (`openFirewall = false`) (`docs/netbird-exposure.md`)

## domains

- defined in `modules/flake-parts/domains.nix`: `flake.domains = { local = "nx3.eu"; public = "fosskar.eu"; }`
- nixos/home access: `self.domains.local` or `flake-self.domains.local`
- flake-parts/clan access: `config.flake.domains.local`
- no `config.domains`; build hostnames from `<sub>.${self.domains.local}`

## vars/secrets

- prefer `clan.core.vars.generators`
- generator name = service
- file name = secret/env filename
- use `clan.core.vars.generators.<service>.files."<file>"`
- manual secret path only when already in use
- shared cross-service generator: `clan.core.vars.generators.smtp` (files `smtp-env`, username, password) reused by gatus, authelia, immich, dawarich, vaultwarden, grafana, msmtp

Example:

```nix
clan.core.vars.generators.myservice = {
  share = true;
  files."filename.ext".secret = false;
  files."secret.key" = { };
  script = "true";
};
```

## verification

- docs/text only: no build
- simple value change: `nix eval` target option
- structural/module/import/package changes: build touched machines

```bash
nix eval .#nixosConfigurations.<machine>.config.<option> --json
nix build .#nixosConfigurations.<machine>.config.system.build.toplevel
```

## debugging

```bash
journalctl -u <service> -f
systemctl status <service>
nix log <store-path>
```

## vcs

Prefer jj over git in colocated repos.

Never run:

- `jj restore`
- `git restore`
- `git checkout -- <file>`

Use:

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

If user says "commit and push": include full working copy scope unless narrowed; split atomically; move `main`; push; do not reconfirm.

## nix/dev

- prefer `nix build`, `nix shell`, `nix develop`
- temp tool: `nix shell nixpkgs#<pkg>`
- format nix: `nix fmt`

## sharp edges

- preservation: root ephemeral; persist explicit dirs/files only (`docs/decisions/state-persistence.md`)
- first install: preservation disabled; enable after secrets land (`machines/README.md`)
- zfs: keep `networking.hostId` stable
- grafana oidc role mapping needs `groups` in `id_token`
- netbird is custom module set here
- netbird reverse proxy: permanent dashboard/API peer targets need service on peer NetBird interface (`0.0.0.0` or NetBird IP); `netbird expose` can expose local `127.0.0.1` via peer-created tunnel
- public exposure is configured in the netbird UI, not the repo; inspect live domain->peer:port mappings read-only in `/var/lib/netbird-server/store.db` on gateway (`docs/netbird-exposure.md`)
- remote-builder: `sshUser = "nix-remote-builder"` needs real shell; nologin breaks `ssh-ng`
- remote-builder proof: `nix build nixpkgs#hello --no-link --option substitute false --max-jobs 0 -L`
- harmonia option: `services.harmonia.cache.*`
- do not force `--build-host localhost` in shell wrappers

## finish

- `nix fmt` after nix edits
- verify proportionally
- track new files if any (`jj file track <path>`)
- do not deploy/restart/update remote machines unless explicit
