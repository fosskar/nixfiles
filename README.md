# nixfiles

<p align="center">
  <img src="https://raw.githubusercontent.com/NixOS/nixos-artwork/master/logo/nix-snowflake-colours.svg" width="300px" alt="nixos logo"/>
</p>

personal nixos infrastructure managed with [clan-core](https://docs.clan.lol/).

## features

- [clan-core](https://docs.clan.lol/) - machine management, secrets (sops-nix), disk partitioning (disko)
- [flake-parts](https://github.com/hercules-ci/flake-parts) - modular flake framework
- [impermanence](https://github.com/nix-community/impermanence) - opt-in state persistence
- [home-manager](https://github.com/nix-community/home-manager) - user environment
- [srvos](https://github.com/nix-community/srvos) - server presets

## machines

| machine       | type        | description              | specs                                                                |
| ------------- | ----------- | ------------------------ | -------------------------------------------------------------------- |
| simon-desktop | desktop     | daily driver workstation | ryzen 7 7800x3d, rx 7800xt, 32gb ddr5                                |
| lpt-titan     | laptop      | framework 13             | ryzen ai 5 340, radeon 840m, 32gb ddr5                               |
| hm-nixbox     | home server | self-hosted services     | ryzen 7 5700x, 64gb, arc b50 pro, 4x6tb + 2x960gb ssd, 2x16gb optane |
| hzc-pango     | vps         | reverse proxy (pangolin) | hetzner cx22                                                         |

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
