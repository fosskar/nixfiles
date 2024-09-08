#

<div align="center">

[![nixos unstable](https://img.shields.io/badge/NixOS-unstable-informational.svg?style=flat&logo=nixos&logoColor=CAD3F5&colorA=24273A&colorB=8AADF4)](https://github.com/nixos/nixpkgs) [![built with nix-flake](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=built%20with%20nix%20flakes&color=41439a)](https://builtwithnix.org)

[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit) [![pipeline status](https://gitlab.com/simonoscr/nixfiles/badges/main/pipeline.svg)](https://gitlab.com/simonoscr/nixfiles/-/commits/main)
[![latest release](https://gitlab.com/simonoscr/nixfiles/-/badges/release.svg)](https://gitlab.com/simonoscr/nixfiles/-/releases)

---

<br>
  <img src="https://raw.githubusercontent.com/NixOS/nixos-artwork/master/logo/nix-snowflake-colours.svg" width="300px" alt="nixos logo"/>
<br>

</div>

---

<div align="center">

## intro

</div>

henlo and welcome to my nixos setup. please be aware that i'm still in the early stages of learning all this. the setup here was created with the help of multiple examples and inspiration from other dotfile and nix-config repositories (see [credits](https://gitlab.com/simonoscr/nixfiles#credits)).

feel free to borrow ideas from my configurations, but keep in mind that they might not always represent the best or most correct approach and make sure you've grasped the basics of nixos, nix, flakes, and home-manager.

> this repository is a work in progress, and i'm constantly learning more about nixos, nix, flakes, and home-manager and all of it's utilities.

<div align="center">

## system components

|                 |     |                                                                                               |
| --------------- | --- | --------------------------------------------------------------------------------------------- |
| display manager |     | [greetd/tuigreet](https://github.com/apognu/tuigreet)                                         |
| window manager  |     | [hyprland](https://github.com/hyprwm/Hyprland)                                                |
| bar             |     | [ags](https://github.com/Aylur/ags)                                                           |
| terminal        |     | [wezterm](https://github.com/wez/wezterm)                                                     |
| shell           |     | zsh + [starship](https://github.com/starship/starship)                                        |
| text editor     |     | [nixvim](https://github.com/nix-community/nixvim)[(neovim)](https://github.com/neovim/neovim) |
| code editor     |     | [vscodium](https://github.com/VSCodium/vscodium)/[zed](https://github.com/zed-industries/zed) |


## systems

|           | desktop               | server                           |
| --------- | --------------------- | -------------------------------- |
| Name      | desktop               | server                           |
| CPU       | amd ryzen 7 7800x3d   | intel® processor alder lake-n100 |
| GPU       | amd radeon rx 7800xt  | intel uhd graphics               |
| RAM       | 32gb ddr5-6000        | 16gb ddr4-3200                   |
| Mainboard | msi mag b650 tomahawk | shit                             |
| SSD       | 2tb nvme              | 500gb nvme                       |

</div>

<div align="center">

## features

</div>

* [**nix-flake**](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html): manage nixos and home-manager configurations.

* [**flake-parts**](https://github.com/hercules-ci/flake-parts): a good way to manage flake with less boilerplate.

* [**home-manager**](https://github.com/nix-community/home-manager): manage your dotfiles, home environment, and user-specific configurations with home-manager.

* [**nh**](https://github.com/viperML/nh): "yet-another-nix-helper". `nh` reimplements some basic nix commands. adding functionality on top of the existing solutions, like nixos-rebuild, home-manager cli or nix itself.

- [**nixvim**](https://www.startpage.com/do/dsearch?query=nixvim+github): nix flake neovim

<div align="center">

## repo layout

</div>

* [**home**](https://gitlab.com/simonoscr/nixfiles/-/tree/main/home): this folder contains configurations for home-manager. In the profiles subfolder are the differenct home-manager profiles. here i have everything user related in it

* [**hosts**](https://gitlab.com/simonoscr/nixfiles/-/tree/main/hosts?ref_type=heads): the hosts/ folder helps me organize my different hosts

* [**images**](https://gitlab.com/simonoscr/nixfiles/-/tree/main/images?ref_type=heads): .nix files for defining different configs for building iso images

* [**modules**](https://gitlab.com/simonoscr/nixfiles/-/tree/main/modules?ref_type=heads): own, custom nixos or home-manager modules

<div align="center">

## search

</div>

* [searchix](https://searchix.alanpearce.eu): all-in-one search tool. search for options and packages for nixos, darwin and home-manager.

* [official nixos search](https://search.nixos.org)
  * [options search](https://search.nixos.org/options)
  * [packages search](https://search.nixos.org/packages)
  * [flakes search](https://search.nixos.org/flakes)
* [home-manager options](https://mipmip.github.io/home-manager-option-search/)
* [nixhub.io](https://www.nixhub.io/) - search versions of nix packages
* [noogle.dev](https://noogle.dev/) - noogle is a Nnx api search engine. it lets you search nix functions.
* [hound](https://search.nix.gsc.io/) - Search nix things?
* [nixpkgs pr-tracker](https://nixpk.gs/pr-tracker.html)

<div align="center">

## guides

</div>

* [official nixos wiki](https://wiki.nixos.org)
  * [nixos installation guide](https://nixos.wiki/wiki/NixOS_Installation_Guide)
  * [nix installation guide](https://nixos.wiki/wiki/Nix_Installation_Guide)
  * [nix flake installation guide](https://nixos.wiki/wiki/Flakes)
* [cachix docs](https://docs.cachix.org/)

<div align="center">

## credits

</div>

my repository is inspired by a diverse range of dotfiles and nix-configurations repositories across github, gitlab (and maybe codeberg). while i've gathered ideas from numerous places, there are a few key repositories that significantly influenced this repository:

* [fufexan dotfiles](https://github.com/fufexan/dotfiles)
  * helped me very much to find a good repository structure and also good and clean .nix configurations and i learned from his repos how to build with nix
* [matt dotfiles](https://gitlab.com/usmcamp0811/dotfiles)
  * also borrowed a little structure and content of .nix files
* [ryan4yin nix-config](https://github.com/ryan4yin/nix-config)
  * helped me a lot for server related configurations
* [Aylur dotfiles](https://github.com/Aylur/dotfiles)
  * thank you very much for ags config
