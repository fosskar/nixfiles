# nixfiles

<p align="center">
  <img src="https://raw.githubusercontent.com/NixOS/nixos-artwork/master/logo/nix-snowflake-colours.svg" width="300px" alt="nixos logo"/>
</p>

personal nixos infrastructure managed with [clan-core](https://docs.clan.lol/).

## features

- [clan-core](https://docs.clan.lol/) - configuration management, secrets (sops-nix), disk partitioning (disko)
- [flake-parts](https://github.com/hercules-ci/flake-parts) - modular flake framework
- [impermanence](https://github.com/nix-community/impermanence) - opt-in state persistence
- [home-manager](https://github.com/nix-community/home-manager) - user configuration

## machines

| machine       | type        | description                              | specs                                 |
| ------------- | ----------- | ---------------------------------------- | ------------------------------------- |
| simon-desktop | desktop     | daily driver workstation                 | ryzen 7 7800x3d, rx 7800xt, 32gb ddr5 |
| hm-nixbox     | home server | self-hosted services (nextcloud, immich) | amd cpu, intel igpu, 2x1tb ssd (zfs)  |
| hzc-pango     | vps         | reverse proxy / tunnel (pangolin)        | hetzner cx22                          |

## documentation

- [nixos manual](https://nixos.org/manual/nixos/stable/)
- [clan-core docs](https://docs.clan.lol/)
- [home-manager options](https://nix-community.github.io/home-manager/options.xhtml)

## credits

- [fufexan dotfiles](https://github.com/fufexan/dotfiles)
- [NotAShelf nyx](https://github.com/notashelf/nyx)
- [ryan4yin nix-config](https://github.com/ryan4yin/nix-config)
- [clan-core](https://git.clan.lol/clan/clan-core)
