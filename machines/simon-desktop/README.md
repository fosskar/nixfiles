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

henlo and welcome to my nixos setup. please be aware that i'm still in the early stages of learning all this. the setup here was created with the help of multiple examples and inspiration from other dotfile and nix-config repositories (see [credits](#credits)).

feel free to borrow ideas from my configurations, but keep in mind that they might not always represent the best or most correct approach and make sure you've grasped the basics of nixos, nix, flakes, and home-manager.

> this repository is a work in progress, and i'm constantly learning more about nixos, nix, flakes, and home-manager and all of it's utilities.

<div align="center">

## system components

|                    |     |                                                                                                         |
| ------------------ | --- | ------------------------------------------------------------------------------------------------------- |
| display manager    |     | [greetd/tuigreet](https://github.com/apognu/tuigreet)                                                   |
| window manager     |     | [hyprland](https://hyprland.org/)                                                                       |
| status bar         |     | [hyprpanel](https://hyprpanel.com/), [quickshell](https://git.outfoxxed.me/quickshell/quickshell)       |
| app launcher       |     | [anyrun](https://github.com/anyrun-org/anyrun)                                                          |
| terminal emulators |     | [ghostty](https://ghostty.org/), [wezterm](https://wezfurlong.org/wezterm/)                             |
| shell              |     | [fish](https://fishshell.com/) + [starship](https://starship.rs/)                                       |
| file manager       |     | [yazi](https://yazi-rs.github.io/)                                                                      |
| text editors       |     | [zed](https://zed.dev/), [neovim](https://github.com/neovim/neovim)                                     |
| browsers           |     | [zen browser](https://zen-browser.app/), [brave](https://brave.com/), [ladybird](https://ladybird.dev/) |

## systems

| | desktop |
<| --------- | --------------------- |
| name | desktop |
| cpu | amd ryzen 7 7800x3d |
| gpu | amd radeon rx 7800xt |
| ram | 32gb ddr5-6000 |>
| mainboard | msi mag b650 tomahawk |
| ssd | 2tb nvme |

</div>

<div align="center">

## features

</div>

- [**nix-flake**](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html): manage nixos and home-manager configurations with reproducible dependency management.

- [**flake-parts**](https://github.com/hercules-ci/flake-parts): modular flake framework for better organization and reusability.

- [**nix-systems**](https://github.com/nix-systems/nix-systems): easy way to manage multiple systems in a flake.

- [**home-manager**](https://github.com/nix-community/home-manager): manage dotfiles, home environment, and user-specific configurations with home-manager.

- [**secrets management**](https://github.com/ryantm/agenix): secure secrets management with agenix (age encryption) and sops-nix.

- [**disko**](https://github.com/nix-community/disko): declarative disk partitioning and formatting for reproducible system installations.

- [**impermanence**](https://github.com/nix-community/impermanence): opt-in state persistence for improved system reproducibility.

- [**nh**](https://github.com/viperML/nh): "yet-another-nix-helper". `nh` reimplements some basic nix commands. adding functionality on top of the existing solutions, like nixos-rebuild, home-manager cli or nix itself.

<div align="center">

## repo layout

</div>

- [**checks**](https://gitlab.com/simonoscr/nixfiles/-/tree/main/checks?ref_type=heads): configuration for checks like pre-commit-hook

- [**home**](https://gitlab.com/simonoscr/nixfiles/-/tree/main/home): this folder contains configurations for home-manager. user-specific configurations like dotfiles, applications, and desktop environment settings

- [**hosts**](https://gitlab.com/simonoscr/nixfiles/-/tree/main/hosts?ref_type=heads): system-specific configurations

- [**lib**](https://gitlab.com/simonoscr/nixfiles/-/tree/main/lib?ref_type=heads): custom library functions and utilities (like scanPaths for automatic module discovery)

- [**overlays**](https://gitlab.com/simonoscr/nixfiles/-/tree/main/overlays?ref_type=heads): nixpkgs overlays for package modifications

- [**packages**](https://gitlab.com/simonoscr/nixfiles/-/tree/main/packages?ref_type=heads): self-packaged pkgs for quick pkgs like packaged appimages etc .

- [**templates**](https://gitlab.com/simonoscr/nixfiles/-/tree/main/templates?ref_type=heads): templates for custom modules, shells or languages

- **customized theming**: coordinated visual appearance across gui and tui applications with consistent colors and styling.

<div align="center">

## search

</div>

- [searchix](https://searchix.alanpearce.eu): all-in-one search tool. search for options and packages for nixos, darwin and home-manager.

- [official nixos search](https://search.nixos.org)
  - [options search](https://search.nixos.org/options)
  - [packages search](https://search.nixos.org/packages)
  - [flakes search](https://search.nixos.org/flakes)
- [home-manager options](https://mipmip.github.io/home-manager-option-search/)
- [nixhub.io](https://www.nixhub.io/) - search versions of nix packages
- [noogle.dev](https://noogle.dev/) - noogle is a Nnx api search engine. it lets you search nix functions.
- [hound](https://search.nix.gsc.io/) - Search nix things?
- [nixpkgs pr-tracker](https://nixpk.gs/pr-tracker.html)

<div align="center">

## guides

</div>

- [official nixos wiki](https://wiki.nixos.org)
  - [nixos installation guide](https://nixos.wiki/wiki/NixOS_Installation_Guide)
  - [nix installation guide](https://nixos.wiki/wiki/Nix_Installation_Guide)
  - [nix flake installation guide](https://nixos.wiki/wiki/Flakes)
- [cachix docs](https://docs.cachix.org/)

<div align="center">

## credits

</div>

my repository is inspired by a diverse range of dotfiles and nix-configurations repositories across github, gitlab (and maybe codeberg). while i've gathered ideas from numerous places, there are a few key repositories that significantly influenced this repository:

- [fufexan dotfiles](https://github.com/fufexan/dotfiles)
  - helped me very much to find a good repository structure and also good and clean .nix configurations and i learned from his repos how to build with nix
- [NotAShelf nyx](https://github.com/notashelf/nyx)
  - it is really comprehensive, overwhelming for me but very very helpful
- [matt dotfiles](https://gitlab.com/usmcamp0811/dotfiles)
  - also borrowed a little structure and content of .nix files
- [ryan4yin nix-config](https://github.com/ryan4yin/nix-config)
  - helped me a lot for server related configurations
- [Aylur dotfiles](https://github.com/Aylur/dotfiles)
  - thank you very much for ags
