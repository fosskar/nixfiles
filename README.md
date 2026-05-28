<p align="center">
  <img src="docs/logo/logo.png" width="300px" alt="nixfiles logo"/>
</p>

personal nixos infrastructure managed with [clan-core](https://docs.clan.lol/). modules follow the [dendritic pattern](https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki): features export reusable aspects, while clan roles and machine imports compose them into concrete systems. the repo covers host configuration, user environments, secrets, storage, networking, and self-hosted services.

## features

- [clan-core](https://docs.clan.lol/) - machine inventory, secrets (sops-nix/age), disk partitioning (disko), service roles and [clanServices](clanServices/)
- [flake-parts](https://flake.parts/) - modular flake framework
- [dendritic pattern](https://github.com/mightyiam/dendritic) - feature/aspect-oriented module structure composed through clan and machine imports
- [home-manager](https://github.com/nix-community/home-manager) - user environments and desktop integration
- [preservation](https://github.com/nix-community/preservation) - opt-in state persistence with ephemeral roots; see [why preservation over impermanence](docs/preservation.md)
- openwrt home network declarative router/ap management

## machines

| machine       | type        | description                | specs                                                                     |
| ------------- | ----------- | -------------------------- | ------------------------------------------------------------------------- |
| simon-desktop | desktop     | daily driver workstation   | dyi: ryzen 7 7800x3d, rx 7800xt, 32gb ddr5                                |
| lpt-titan     | laptop      | remote work                | framework 13: ryzen ai 5 340, radeon 840m, 32gb                           |
| nixbox        | home server | self-hosted services       | dyi: ryzen 7 5700x, 64gb, arc b50 pro, 4x6tb + 2x960gb ssd, 2x16gb optane |
| nixworker     | home server | ci, remote builder, cache  | minisforum ms-a2: ryzen 9 9955hx, 96gb ddr5                               |
| gateway       | vps         | gw/reverse proxy (netbird) | hetzner cx23: 2vcpu, 4gb ram, 40gb ssd                                    |

## documentation

- [repo docs](docs/)
- [machine docs](machines/README.md)
- [nixos search](https://search.nixos.org/)
- [clan-core docs](https://docs.clan.lol/)
- [dendritic pattern wiki](https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki)
- [flake-parts docs](https://flake.parts/)

## credits

- [mic92 dotfiles](https://github.com/Mic92/dotfiles)
- [badele nix-homelab](https://github.com/badele/nix-homelab)
- [ryan4yin nix-config](https://github.com/ryan4yin/nix-config)
- [fufexan dotfiles](https://github.com/fufexan/dotfiles)
- [NotAShelf nyx](https://github.com/notashelf/nyx)

## license

[WTFPL](LICENSE)
