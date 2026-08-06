# nixfiles agent playbook

## rules

- declarative first; no manual drift
- no destructive remote actions unless explicit; do not run `clan machines update`, `reboot`, or `systemctl restart` by default
- avoid Nix `with`; use explicit attrs
- unused or unimported modules are ready-to-enable aspects, not dead code; never remove one only because nothing imports it

## architecture

- feature modules export reusable aspects through `flake.modules.<class>.<name>`
- imports are the primary enable mechanism; machine files and clan roles are composition edges
- keep imports unconditional; guard conditional configuration instead
- feature modules own related homepage, gatus, reverse proxy, desktop shortcut, and window-rule integration
- collectors gather contributions; they are not broad roles or profiles
- search all contributors before editing an exported collector; one aspect can have several contributors
- `modules/` is auto-loaded by `import-tree`; an `_` prefix excludes a path
- `nflib.scanPaths ./. { }` loads directories and `.nix` files except `default.nix`, `flake-module.nix`, `configuration.nix`, `disko.nix`, and `home.nix`; an `_` prefix has no special meaning

Source routing:

- global service behavior: `modules/nixos/services/`
- host-local composition and hardware: `machines/<machine>/`
- common roles: `modules/nixos/common/`
- clan inventory and role assignment: `machines/flake-module.nix`
- reusable clan services: `clan-services/<service>/default.nix`
- flake-level data and wiring: `modules/flake-parts/`
- local packages: `packages/<name>/package.nix`; exposed as flake package `<name>` and `pkgs.local.<name>`

Non-obvious areas:

- `modules/flake-parts/clan.nix` registers `clan-services/<service>` as `clan.modules.<service>`
- `modules/flake-parts/hosts.nix` is the single source of machine IPs
- `modules/llm/` owns agent tooling, skills, souls, and extensions; pi and omp install their applicable extensions
- `flake.llm.skills.<name>` exposes skills to NixOS consumers such as Hermes
- OpenWrt configuration belongs in `openwrt/`, not on the device

## clan

Clan owns inventory, tags, vars, and service role assignment. Host files own host-local composition and hardware or storage.

- inspect inventory and service definitions before using deployment or runtime commands for discovery
- prefer `clan.core.vars.generators`; keep service-specific secrets with the service
- the shared SMTP generator is `clan.core.vars.generators.smtp`
- machine IDs come from `machines/flake-module.nix`
- prefer `clan ssh <machine>` for inventory machines
- `clan ssh <machine> -c` takes an argv list; pipelines need `sh -c`

## service exposure

Services declare their own dashboard tile, health check, and reverse proxy defaults. Do not add a service registry. The `nixfiles.webServices` abstraction was rejected in 2026-07; keep hand-written per-module stanzas.

- non-homepage hosts can set `services.homepage-dashboard.services`; do not guard tiles on `services.homepage-dashboard.enable`
- non-gatus hosts can set `services.gatus.settings.endpoints`; do not guard endpoints on `services.gatus.enable`
- `modules/nixos/services/{homepage,gatus}/collector.nix` collects remote entries and excludes itself
- caddy has no cross-host collector; local routes use `services.caddy.virtualHosts.<host>.extraConfig`
- public `*.fosskar.eu` ingress uses netbird-proxy on `gateway`, configured in the NetBird UI
- public targets go directly to `peer:appPort`; bind the service to `0.0.0.0` or the NetBird interface and keep `openFirewall = false`
- see `docs/netbird-exposure.md` before changing public exposure

## domains

- `modules/flake-parts/domains.nix` defines `local = "nx3.eu"` and `public = "fosskar.eu"`
- NixOS and home-manager modules use `self.domains` or `flake-self.domains`
- flake-parts and clan modules use `config.flake.domains`
- there is no `config.domains`

## verification

- docs-only changes need no build
- evaluate simple option changes with `nix eval .#nixosConfigurations.<machine>.config.<option> --json`
- build structural module or import changes with `nix build .#nixosConfigurations.<machine>.config.system.build.toplevel`
- for several targets, use `nix develop -c nix-fast-build --skip-cached --flake .#checks.x86_64-linux.<attr>`; check names include `nixos-<machine>`, `home-<name>`, `package-<name>`, and `devshell-<name>`

## sharp edges

- preservation makes root ephemeral; persist state explicitly under `preservation.preserveAt."/persist"`
- keep preservation disabled for first install; enable it after secrets land (`machines/README.md`)
- keep `networking.hostId` stable on ZFS machines
- public NetBird mappings live in the UI; inspect them read-only in `/var/lib/netbird-server/store.db` on `gateway`
- `netbird expose` can expose a loopback service through a peer-created tunnel; permanent peer targets cannot use loopback
- remote-builder `sshUser = "nix-remote-builder"` needs a real shell; nologin breaks `ssh-ng`
- test remote-builder use with `nix build nixpkgs#hello --no-link --option substitute false --max-jobs 0 -L`
- Harmonia cache options use `services.harmonia.cache.*`
- Grafana OIDC role mapping needs `groups` in `id_token`
- do not force `--build-host localhost` in shell wrappers
