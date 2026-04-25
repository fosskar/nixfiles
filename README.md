<p align="center">
  <img src="docs/logo/logo.svg" width="300px" alt="nixfiles logo"/>
</p>

personal nixos infrastructure managed with [clan-core](https://docs.clan.lol/). modules follow the [dendritic pattern](https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki), using `flake.modules.*` as the public module api and machine/clan imports as the composition edge.

## features

- [dendritic pattern](https://github.com/mightyiam/dendritic) - feature/aspect-oriented module structure inspired by the [dendritic wiki](https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki)
- [clan-core](https://docs.clan.lol/) - machine management, secrets (sops-nix/age), disk partitioning (disko), services (clanServices)
- [flake-parts](https://github.com/hercules-ci/flake-parts) - modular flake framework
- [preservation](https://github.com/nix-community/preservation) - opt-in state persistence
- [home-manager](https://github.com/nix-community/home-manager) - user environment
- [srvos](https://github.com/nix-community/srvos) - server presets

## machines

| machine       | type        | description                | specs                                                                     |
| ------------- | ----------- | -------------------------- | ------------------------------------------------------------------------- |
| simon-desktop | desktop     | daily driver workstation   | dyi: ryzen 7 7800x3d, rx 7800xt, 32gb ddr5                                |
| lpt-titan     | laptop      | remote work                | framework 13: ryzen ai 5 340, radeon 840m, 32gb                           |
| nixbox        | home server | self-hosted services       | dyi: ryzen 7 5700x, 64gb, arc b50 pro, 4x6tb + 2x960gb ssd, 2x16gb optane |
| nixworker     | home server | ci, remote builder, cache  | minisforum ms-a2: ryzen 9 9955hx, 96gb ddr5                               |
| gateway       | vps         | gw/reverse proxy (netbird) | hetzner cx23: 2vcpu, 4gb ram, 40gb ssd                                    |

## documentation

- [nixos manual](https://nixos.org/manual/nixos/stable/)
- [clan-core docs](https://docs.clan.lol/)
- [home-manager options](https://nix-community.github.io/home-manager/options.xhtml)
- [flake-parts docs](https://flake.parts/)

## credits

- [fufexan dotfiles](https://github.com/fufexan/dotfiles)
- [NotAShelf nyx](https://github.com/notashelf/nyx)
- [ryan4yin nix-config](https://github.com/ryan4yin/nix-config)
- [mic92 dotfiles](https://github.com/Mic92/dotfiles)
- [badele nix-homelab](https://github.com/badele/nix-homelab)

## license

[MIT](LICENSE)
