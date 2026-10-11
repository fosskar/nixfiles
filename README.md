<p align="center">
  <img src="docs/logo/logo.svg" width="120px" alt="nixfiles logo"/>
</p>

<p align="center">
  <a href="https://nixbot.fosskar.eu/repos/github/fosskar/nixfiles"><img src="https://nixbot.fosskar.eu/badge/a90f69ca-78e7-4d60-b303-b411de630dcc.svg" alt="nixbot"/></a>
</p>

personal nixos infrastructure managed with [clan-core](https://docs.clan.lol/). modules are feature-oriented: feature modules export reusable features through `flake.modules.*`, while clan roles and machine imports compose them into concrete systems. the repo covers host configuration, user environments, secrets, storage, networking, and self-hosted services.

## stack

- [clan-core](https://docs.clan.lol/) - machine inventory, secrets (sops-nix/age), disk partitioning (disko), service roles and [clan-services](modules/clan-services/)
- [flake-parts](https://flake.parts/) - modular flake framework
- feature-oriented module structure - feature modules export features through `flake.modules.*`, composed through clan roles and machine imports
- [home-manager](https://github.com/nix-community/home-manager) - user environments and desktop integration
- [preservation](https://github.com/nix-community/preservation) - opt-in state persistence with ephemeral roots; see [why preservation over impermanence](docs/decisions/state-persistence.md)
- openwrt home network declarative router/ap management

## layout

```
inventory/        clan inventory: machines, tags, service instances and role assignment
machines/<name>/  host-local composition, hardware, disks
modules/
  nixos/          nixos features: common roles, services, hardware, filesystems, boot
  home-manager/   home-manager features: shell, cli, editors, desktop
  clan-services/  reusable clan services with roles and vars
  llm/            coding agent configs, skills, souls
  flake-parts/    flake-level wiring: hosts, domains, packages, ci effects, openwrt
users/            per-user home-manager composition
packages/         local packages, exposed as flake packages and pkgs.local.*
openwrt/          router and access point config, rendered to uci
templates/        flake templates for new projects, modules, and clan services
```

imports are the enable mechanism. each feature owns its integrations: dashboard tile, health check, reverse proxy route, grafana dashboards, and alerts; homepage and gatus collect them across hosts, so there is no central service registry.

## notable work

**system & state**

- [zfs snapshot before every switch](modules/nixos/filesystems/zfs/preswitch-snapshot.nix) - a broken migration rolls back to the moment before the switch
- [ephemeral root](modules/nixos/boot/preservation/) - root rolled back on boot, state persisted explicitly through preservation
- [immutable /etc](modules/nixos/boot/immutable.nix) - `/etc` as an erofs overlay
- [snapshot-backed backups](modules/clan-services/snapshot-backup/) - filesystem snapshots as the source for borgbackup

**local llm & agents**

- [llama.cpp](modules/nixos/services/llama-cpp.nix) - local model router with pinned models; [model selection](docs/decisions/local-llama-model-selection.md)
- [hermes](modules/clan-services/hermes/) - hermes agents as clan service instances, each sealed in a [fencr](https://github.com/fosskar/fencr) microvm sandbox
- [agent tooling](modules/llm/) - coding agents configured from one place, with [pi-pack](https://github.com/fosskar/pi-pack) and [local skills](modules/llm/skills/)
- [remote workspace](modules/home-manager/workspace/) - a headless dev host that uses the workstation's agents and browser through forwarded sockets

**build & ci**

- [nixbot](modules/nixos/services/nixbot/) ci with [scheduled effects](modules/flake-parts/effects.nix) and an [updater pipeline](packages/updater/) that opens update prs
- [remote builds](modules/clan-services/nix-grpc-store/) over nix-grpc-store and self-hosted [binary caches](modules/clan-services/niks3/)

**network & security**

- [netbird](modules/clan-services/netbird/) - self-hosted overlay network and public ingress; [why netbird](docs/decisions/overlay-network.md)
- sso with authelia and lldap; [why](docs/decisions/sso-stack.md)
- [openwrt](openwrt/) - router and access points managed declaratively from nix
- yubikey as openpgp ssh key; [why](docs/decisions/yubikey-openpgp-ssh.md)

**observability**

- [monitoring](modules/clan-services/monitoring/) - metrics, logs, dashboards, and alerts as a clan service

**desktop**

- niri with [noctalia-shell](https://github.com/noctalia-dev/noctalia-shell)
- [noctalia v5 plugins](modules/home-manager/desktop/noctalia/plugins/) - luau plugins shipped straight from the repo as a local plugin source

**everything else**

- [self-hosted services](modules/nixos/services/)
- [local packages](packages/) - packages not in nixpkgs
- [templates](templates/) - flake templates

## ai

i work heavily with ai coding agents, in this repo and elsewhere, and i am open about it. i also try not to annoy anyone with ai slop: my agents follow [shared writing instructions](modules/llm/AGENTS.md), [prose-lint](packages/prose-lint/) catches llm writing tells, and i review every change before it lands. commits written with an agent carry the linux kernel's `Assisted-by: LLM` trailer.

## decisions

notable migrations and tradeoffs get a decision record in [docs/decisions](docs/decisions/):

- [preservation over impermanence](docs/decisions/state-persistence.md)
- [openpgp card ssh key over fido2 and piv](docs/decisions/yubikey-openpgp-ssh.md)
- [github over codeberg](docs/decisions/code-forge.md)
- [netbird over tailscale and pangolin](docs/decisions/overlay-network.md)
- [authelia + lldap over pocket-id, kanidm, and the enterprise idps](docs/decisions/sso-stack.md)
- [caddy over nginx](docs/decisions/reverse-proxy.md)
- [opencloud over nextcloud + paperless](docs/decisions/personal-cloud.md)
- [local llama.cpp model selection](docs/decisions/local-llama-model-selection.md)
- [zfs: legacy mountpoints for every mounted dataset](docs/decisions/zfs.md)

## machines

topology, networks, and per-machine details are in [machines/README.md](machines/README.md).

| machine   | type        | description                | specs                                                                                          |
| --------- | ----------- | -------------------------- | ---------------------------------------------------------------------------------------------- |
| desktop   | desktop     | daily driver workstation   | dyi: ryzen 7 7800x3d, rx 7800xt, 32gb ddr5                                                     |
| lpt-titan | laptop      | remote work                | framework 13: ryzen ai 5 340, radeon 840m, 32gb                                                |
| nixbox    | home server | self-hosted services       | dyi: ryzen 7 5700x, 64gb, nvidia rtx pro 4000 backwell sff, 4x6tb + 2x960gb ssd, 2x16gb optane |
| nixworker | home server | ci, remote builder, cache  | minisforum ms-a2: ryzen 9 9955hx, intel arc pro b50, 96gb ddr5                                 |
| gateway   | vps         | gw/reverse proxy (netbird) | hetzner cx23: 2vcpu, 4gb ram, 40gb ssd                                                         |

## credits

- [badele nix-homelab](https://github.com/badele/nix-homelab)
- [fufexan dotfiles](https://github.com/fufexan/dotfiles)
- [mic92 dotfiles](https://github.com/Mic92/dotfiles)
- [NotAShelf nyx](https://github.com/notashelf/nyx)
- [pinpox nixos-config](https://github.com/pinpox/nixos)
- [ryan4yin nix-config](https://github.com/ryan4yin/nix-config)
- [sini nix-config](https://github.com/sini/nix-config)
