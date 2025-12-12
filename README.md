#

<div align="center">

[![nixos unstable](https://img.shields.io/badge/NixOS-unstable-informational.svg?style=flat&logo=nixos&logoColor=CAD3F5&colorA=24273A&colorB=8AADF4)](https://github.com/nixos/nixpkgs) [![built with nix flake](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

---

<br>
  <img src="https://raw.githubusercontent.com/NixOS/nixos-artwork/master/logo/nix-snowflake-colours.svg" width="300px" alt="nixos logo"/>
<br>

</div>

---

<div align="center">

## intro

</div>

henlo and welcome to my nixos infrastructure. this repository manages my personal nix infrastructure using [clan-core](https://docs.clan.lol/) for nixos configuration management across desktop machines, lxc containers, and cloud vms.

> **Note**
>
> this repository is a work in progress, constantly evolving as i learn more about nixos and its ecosystem.

> **Warning**
>
> these configurations are personal and may not represent best practices. make sure you understand nixos, nix flakes, and clan-core basics before using these configs in your own setup.

<div align="center">

## infrastructure overview

</div>

|                 |                                                                                                                                                                                                           |
| --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **desktop**     | simon-desktop (amd ryzen 7 7800x3d, rx 7800xt, 32gb ddr5)                                                                                                                                                 |
| **proxmox lxc** | arr, backup, dashboard, fileserver, gateway, immich, llm, media, monitoring, nextcloud, oidc, paperless, reverseproxy, vaultwarden                                                                        |
| **cloud vps**   | hzc-pango (hetzner cloud cx22: 2 cpu, 4gb ram, 40gb disk)                                                                                                                                                 |
| **config mgmt** | [clan-core](https://docs.clan.lol/) (includes sops-nix for secrets, disko for disk config)                                                                                                                |
| **persistence** | [impermanence](https://github.com/nix-community/impermanence) for opt-in state                                                                                                                            |
| **home config** | [home-manager](https://github.com/nix-community/home-manager)                                                                                                                                             |
| **desktop env** | [hyprland](https://hyprland.org/) + [hyprpanel](https://hyprpanel.com/) + [ghostty](https://ghostty.org/) + [zed](https://zed.dev/) + [fish](https://fishshell.com/) + [yazi](https://yazi-rs.github.io/) |

<div align="center">

## features

</div>

- **[clan-core](https://docs.clan.lol/)**: role-based configuration management with inventory system for organizing machines by tags and deploying configurations across multiple hosts. integrates sops-nix for secrets management and disko for declarative disk partitioning.

- **[flake-parts](https://github.com/hercules-ci/flake-parts)**: modular flake framework for better organization and reusability across the entire infrastructure.

- **[impermanence](https://github.com/nix-community/impermanence)**: opt-in state persistence for improved system reproducibility. root filesystem cleared on boot, only persisting explicitly declared paths.

- **[home-manager](https://github.com/nix-community/home-manager)**: manage dotfiles, home environment, and user-specific configurations declaratively.

- **tag-based organization**: machines organized with tags (desktop, lxc, px-prd1, hetzner) for flexible role assignment and deployment targeting.

- **modular architecture**: shared modules, instances, and roles enable dry configuration across all infrastructure components.

<div align="center">

## machines

</div>

### desktop

|           | simon-desktop         |
| --------- | --------------------- |
| cpu       | amd ryzen 7 7800x3d   |
| gpu       | amd radeon rx 7800xt  |
| ram       | 32gb ddr5-6000        |
| mainboard | msi mag b650 tomahawk |
| storage   | 2tb nvme              |
| features  | impermanence, disko   |

### lxc containers (proxmox px-prd1)

| machine      | purpose              | ip         |
| ------------ | -------------------- | ---------- |
| arr          | media automation     | 10.0.0.110 |
| backup       | backup services      | 10.0.0.98  |
| dashboard    | monitoring dashboard | 10.0.0.103 |
| fileserver   | samba shares         | 10.0.0.104 |
| gateway      | network gateway      | 10.0.0.100 |
| immich       | photo management     | 10.0.0.107 |
| llm          | llm services         | 10.0.0.106 |
| media        | media server         | 10.0.0.111 |
| monitoring   | prometheus/grafana   | 10.0.0.102 |
| nextcloud    | cloud storage        | 10.0.0.112 |
| oidc         | authentication       | 10.0.0.105 |
| paperless    | document management  | 10.0.0.108 |
| reverseproxy | nginx reverse proxy  | 10.0.0.101 |
| vaultwarden  | password manager     | 10.0.0.109 |

### cloud vps

| machine   | provider             | type | specs                     | purpose         | ip             |
| --------- | -------------------- | ---- | ------------------------- | --------------- | -------------- |
| hzc-pango | hetzner cloud (cx22) | vps  | 2 cpu, 4gb ram, 40gb disk | public services | 138.201.155.21 |

<div align="center">

## repo layout

</div>

- **[machines](machines/)**: machine-specific configurations organized by hostname. each machine contains its specific settings, hardware config, and module imports. clan inventory defined in `machines/flake-module.nix`.

- **[sops](sops/)**: secrets management structure with age keys and encrypted secrets. contains user and machine-specific encryption keys organized for clan vars system.

- **[vars](vars/)**: clan vars configuration for managing machine-specific variables and secrets. organized per-machine with symlinks to sops keys.

- **[home](home/)**: home-manager configurations for user-specific settings, dotfiles, applications, and desktop environment configurations.

- **[lib](lib/)**: custom library functions and utilities including scanPaths for automatic module discovery and helper functions.

- **[modules](modules/)**: shared nixos modules imported across machines. contains reusable configuration components.

- **[overlays](overlays/)**: nixpkgs overlays for package modifications and custom package definitions.

- **[packages](packages/)**: custom packaged software including appimages, local packages, and quick package definitions.

- **[shells](shells/)**: development shells including default shell with clan-cli and agenix-rekey, plus terraform shell for infrastructure management.

- **[templates](templates/)**: templates for custom modules, shells, and language environments.

- **[checks](checks/)**: configuration for pre-commit hooks and automated checks.

<div align="center">

## quick start

</div>

### development environment

```bash
# enter development shell (includes clan-cli, agenix-rekey)
nix develop

# check configuration
nix flake check

# format code
nix fmt
```

### managing machines

```bash
# update machine configuration
clan machines update <machine-name>

# build specific machine
nix build .#clanInternals.machines.x86_64-linux.simon-desktop.config.system.build.toplevel

# update all machines secrets
clan vars generate --all
```

### secrets management

```bash
# generate secrets for a machine
clan vars generate <machine-name> root-password

# list all vars for a machine
clan vars list <machine-name>

# rekey secrets (agenix-rekey)
agenix-rekey
```

### deployment

```bash
# deploy using clan
clan machines install <machine-name>

# or using nixos-rebuild
nixos-rebuild switch --flake .#<machine-name>
```

### terraform (infrastructure)

```bash
# enter terraform shell
nix develop .#terraform

# plan/apply infrastructure changes
tofu plan
tofu apply
```

<div align="center">

## search & documentation

</div>

### nix search tools

- [searchix](https://searchix.alanpearce.eu) - all-in-one search for nixos, darwin, home-manager
- [official nixos search](https://search.nixos.org) - packages, options, flakes
- [home-manager options](https://mipmip.github.io/home-manager-option-search/)
- [nixhub.io](https://www.nixhub.io/) - package version history
- [noogle.dev](https://noogle.dev/) - nix function search
- [nixpkgs pr-tracker](https://nixpk.gs/pr-tracker.html)

### documentation

- [nixos manual](https://nixos.org/manual/nixos/stable/)
- [nix flakes wiki](https://nixos.wiki/wiki/Flakes)
- [clan-core docs](https://docs.clan.lol/)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [disko](https://github.com/nix-community/disko)
- [impermanence](https://github.com/nix-community/impermanence)

<div align="center">

## credits

</div>

this repository is inspired by a diverse range of nix configurations across the community:

- [fufexan dotfiles](https://github.com/fufexan/dotfiles) - repository structure and clean nix configurations
- [NotAShelf nyx](https://github.com/notashelf/nyx) - comprehensive configuration examples
- [matt dotfiles](https://gitlab.com/usmcamp0811/dotfiles) - module structure inspiration
- [ryan4yin nix-config](https://github.com/ryan4yin/nix-config) - server configuration patterns
- [clan-core](https://git.clan.lol/clan/clan-core) - infrastructure management framework

special thanks to the nixos community for their extensive documentation and examples.
