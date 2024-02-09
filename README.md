#

<div align="center">

[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix%20Flakes&color=41439a)](https://builtwithnix.org) [![NixOS unstable](https://img.shields.io/badge/NixOS-unstable-informational.svg?style=flat&logo=nixos&logoColor=CAD3F5&colorA=24273A&colorB=8AADF4)](https://github.com/nixos/nixpkgs)



</div>

---

<br>
<div align="center">
  <img src="https://raw.githubusercontent.com/NixOS/nixos-artwork/master/logo/nixos-white.png" width="500px" alt="NixOS logo"/>
</div>
<br>

---

## Intro

Hello and welcome to my NixOS setup. Please be aware that I'm still in the early stages of learning all this. The setup here was created with the help of multiple examples and inspiration from other dotfile and nix-config repositories (see [Credits](##Credits)).

Feel free to borrow ideas from my configurations, but keep in mind that they might not always represent the best or most correct approach and make sure you've grasped the basics of NixOS, Nix, Flakes, and Home-Manager.

This repository is a work in progress, and I'm constantly learning more about NixOS, Nix, Flakes, and Home-Manager.

## :snowflake: System Components

| | NixOS - Wayland | NixOS - Xorg |
|-|-----------------|--------------|
| Display Manager | greetd/tuigreet | greetd/tuigreet |
| Window Manager | Hyprland | i3 |
| Bar | Waybar | Polybar |
| Terminal| Kitty | Kitty |
| Shell | zsh + Starship | zsh + Starship |
| Text Editor | Nixvim(Neovim) | Nixvim(Neovim) |
| Code Editor | VSCodium | VSCodium |
| System resource monitor | btop | btop |
| Fonts | Roboto | - |

## Systems

| | MainPC - NixOS | Server - NixOS |
|-|-----------------|--------------|
| Name | Cosmos | Voyager |
| CPU | AMD Ryzen 7 7800X3D | Intel® Processor Alder Lake-N100 |
| GPU | AMD Radeon RX 7800 XT | Intel UHD Graphics |
| RAM | 32GB DDR5-6000 | 16GB DDR4-3200 |
| Mainboard | MSI MAG B650 Tomahawk | bad |
| SSD | 2TB NVMe | 500GB NVMe |
| MISC | - | - |

## Features

- **Nix Flake**: Manage NixOS and Home-Manager configurations.

- **Home Manager**: Manage your dotfiles, home environment, and user-specific configurations with Home Manager.

- **NUR Integration**: Access the Nix User Repository (NUR) for additional packages and enhancements.

- **Alejandra**: Nix linting

- **NixVim**: Nix Flake Neovim config

## :snowflake: Layout

- **Configuration Modules**: The modules/ folder allows you to set up NixOS modules tailored for different platforms like nixos, darwin, and home, making system configuration management more modular.

- **Overlays**: Use the overlays/ directory for any custom overlays you may have.

- **System Configurations**: The hosts/ folder helps you organize your system setups by architecture and format, enabling configurations for multiple platforms.

- **Home Environment Configs**: Similarly, the homes/ folder arranges configurations by architecture, which is particularly handy for managing home environments via Nix.

## Search

- [Nix Search](https://search.nixos.org) - Search for Nix packages, NixOS options or Flakes
- [Home-Manager Options](https://mipmip.github.io/home-manager-option-search/) - Search for Home-Manager options
- [Nixhub.io](https://www.nixhub.io/) - Search Versions of nix packages
- [Noogle.dev](https://noogle.dev/) - Noogle is a Nix API search engine. It lets you search nix functions.
- [Hound](https://search.nix.gsc.io/) -




## Guides

- [NixOS Installation Guide](https://nixos.wiki/wiki/NixOS_Installation_Guide)
- [Nix Installation Guide](https://nixos.wiki/wiki/Nix_Installation_Guide)
- [Nix Flake Installation Guide](https://nixos.wiki/wiki/Flakes)
- [Snowfall Quickstart Guide](https://snowfall.org/guides/lib/quickstart/)


## Credits

My repository is inspired by a diverse range of dotfiles and nix-configurations repositories across GitHub, Codeberg, and GitLab. While I've gathered ideas from numerous places, there are a few key repositories that significantly influenced this repository:

- [Matt Dotfiles](https://gitlab.com/usmcamp0811/dotfiles)
- [ryan4yin nix-config](https://github.com/ryan4yin/nix-config)
- [Aylur dotfiles](https://github.com/Aylur/dotfiles)
