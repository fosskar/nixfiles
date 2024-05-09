## [2.7.2](https://gitlab.com/simonoscr/nixfiles/compare/2.7.1...2.7.2) (2024-05-09)


### ⚠ BREAKING CHANGES

* restructure repo to better reflect what files are used in different hosts; also deleted unused file and split many files up to see better where to find what

### :scissors: Refactor

* restructure repo to better reflect what files are used in different hosts; also deleted unused file and split many files up to see better where to find what ([8d5369a](https://gitlab.com/simonoscr/nixfiles/commit/8d5369a575005606fdda804ed30dfadcffd922a9))


### 📔 Docs

* update README ([8aa3054](https://gitlab.com/simonoscr/nixfiles/commit/8aa3054631dfdd5bc042b3bfc4cf84c1be4ac41d))


### 📦 Other

* **flake:** update flake.lock ([1519f96](https://gitlab.com/simonoscr/nixfiles/commit/1519f96ca2e0eb4ccb8b65050b38f76f294bf773))
* **flake:** update flake.lock ([3ab156e](https://gitlab.com/simonoscr/nixfiles/commit/3ab156e9133b690f77cd63a9c43a89f819ba20b3))


### 🦊 CI/CD

* switch default image ([41c757b](https://gitlab.com/simonoscr/nixfiles/commit/41c757b210185cf90faa805f1f8611f791259666))
* test build and push to cachix ([b0068bf](https://gitlab.com/simonoscr/nixfiles/commit/b0068bfc0cda1c1cb98fbddb0f389fcffbab05a3))
* **fix:** remove ${CI_PROJECT_DIR} from nix build, invalid url just use "." ([b755027](https://gitlab.com/simonoscr/nixfiles/commit/b755027dfe3a7c83b93cb25b4f41bd7abd45cfe3))
* **fix:** valid build stage ([25f6c5f](https://gitlab.com/simonoscr/nixfiles/commit/25f6c5f2bf414045f7ffcd53effb175cc737a2ca))
* **test:** fix typo in nix build ([5d37783](https://gitlab.com/simonoscr/nixfiles/commit/5d37783e91d236072eaf6b3cfffa0c622d432ea4))


### 🧪 Tests

* **ci:** add jq to get inputs value.path from nix flake json archive ([0ebe4d7](https://gitlab.com/simonoscr/nixfiles/commit/0ebe4d71cde077940711251b46cbd63baa1b3fd9))
* **ci:** add jq with nix-shell --run and execute nix flake archive in pipeline ([31de671](https://gitlab.com/simonoscr/nixfiles/commit/31de671f765a9a7c87922499dc98d37311a5d5bd))
* **ci:** build in pipeline and push to cachix ([27d1c86](https://gitlab.com/simonoscr/nixfiles/commit/27d1c8600309b829517805caf4e838da2cc064fa))
* **ci:** nix build flake ([3a21da3](https://gitlab.com/simonoscr/nixfiles/commit/3a21da34187f1f4e126c0c295535fd90bf561522))
* **ci:** test nix flake archive instead of nix build, because gitlab-runner has not enought disk space ([54b049d](https://gitlab.com/simonoscr/nixfiles/commit/54b049d254ff606dcd678d8e04be6a991a86c2d5))
* **ci:** try h in gitlab pipeline ([8304da1](https://gitlab.com/simonoscr/nixfiles/commit/8304da1bd67d2a7f44ad135ea8c7ea7e0597fea0))

## [2.7.1](https://gitlab.com/simonoscr/nixfiles/compare/2.7.0...2.7.1) (2024-05-06)


### 📦 Other

* **firefox:** add cachix to bookmarks ([5cb5915](https://gitlab.com/simonoscr/nixfiles/commit/5cb591578340e2c30e27ec791ea2cf5f063d9170))
* **flock:** update flake.lock ([0e83fb1](https://gitlab.com/simonoscr/nixfiles/commit/0e83fb12af2f87e35f1babc83c34061539734479))


### 🛠 Fixes

* **flake:** hyprland flake input; ags follow nixpkgs, remove old inputs ([ab3725c](https://gitlab.com/simonoscr/nixfiles/commit/ab3725cf160e9a232eecc7dfc32dc1f80a63a1e7))
* **hm:** outsource home-manager settings to own .nix file instead of flake ([0d359c4](https://gitlab.com/simonoscr/nixfiles/commit/0d359c4c57b89f48396a7c241e0d2dac1c474505))
* **hyprland:** add systemd variables and extraCommands ([a0ea2d4](https://gitlab.com/simonoscr/nixfiles/commit/a0ea2d45603ce3ef72cbc75a99265ff299824945))
* **hyprland:** install hyprland for system instead only with hm; should be better and should added some dependencies; update imports on configuration ([920ebe6](https://gitlab.com/simonoscr/nixfiles/commit/920ebe6610fbbff0048a501eb3c8a7c33922033d))

## [2.7.0](https://gitlab.com/simonoscr/nixfiles/compare/2.6.2...2.7.0) (2024-05-05)


### 📦 Other

* **flake.lock:** update flock ([3b8260a](https://gitlab.com/simonoscr/nixfiles/commit/3b8260af473df6f494e7d8cf9e41165118ee6662))


### 🦊 CI/CD

* remove 'only' rules for all jobs and stages ([7cd835f](https://gitlab.com/simonoscr/nixfiles/commit/7cd835f0d56c280ae32e2ed6d71c730155710528))


### 🚀 Features

* add and use own cachix cache ([0c68474](https://gitlab.com/simonoscr/nixfiles/commit/0c684740988e637ef7ad40549afda2dd47095194))

## [2.6.2](https://gitlab.com/simonoscr/nixfiles/compare/2.6.1...2.6.2) (2024-05-05)


### :scissors: Refactor

* avoid repeated keys in attribute sets ([70c8d7f](https://gitlab.com/simonoscr/nixfiles/commit/70c8d7f0c60b692a0a5fcf2b9d179168b490e1bd))


### 📦 Other

* update flock ([9008b0e](https://gitlab.com/simonoscr/nixfiles/commit/9008b0e61666cda780a1ef522ba641914f6df7f9))


### 🛠 Fixes

* **ags:** update ags version to 1.8.2 and disable matugen ([54147fd](https://gitlab.com/simonoscr/nixfiles/commit/54147fdb4b51ba0803989f08a46ee4a6875dd116))

## [2.6.1](https://gitlab.com/simonoscr/nixfiles/compare/2.6.0...2.6.1) (2024-05-04)


### 📦 Other

* fix releaserc ([151fe05](https://gitlab.com/simonoscr/nixfiles/commit/151fe059eca1e7a043f7d7754ddf615c7c44a1b5))
* make refactor commit also da patch release ([6befabf](https://gitlab.com/simonoscr/nixfiles/commit/6befabfc2f64a9ec367638032c705a87cf2cb3db))
* update flock ([540a913](https://gitlab.com/simonoscr/nixfiles/commit/540a913795ba2e041e3fe0bd7b1d72515b68ae41))


### 🦊 CI/CD

* added cache for npm ([59552fc](https://gitlab.com/simonoscr/nixfiles/commit/59552fc1b175ead5df6c9a78e58a17d53c25ab89))
* fixonventional-changelog-conventionalcommits @ v7.0.2 ([ab608ae](https://gitlab.com/simonoscr/nixfiles/commit/ab608aebee52f9ed1668660ca56fbb2460102099))
* remove npm cache from release job ([0004e4f](https://gitlab.com/simonoscr/nixfiles/commit/0004e4f0236ebdfcdbeade80d1fe28705a3b78f3))


### 🛠 Fixes

* disable hyprland debug log but keep option in hyprland config ([7ececd6](https://gitlab.com/simonoscr/nixfiles/commit/7ececd6458bc49bdf971bb9eea5390af4ea6b285))
* hyprland config option to disable or enable debug logs ([6016a08](https://gitlab.com/simonoscr/nixfiles/commit/6016a0895ae0b10745ff2f8592d9a2d936a9174b))

## [2.6.0](https://gitlab.com/simonoscr/nixfiles/compare/v2.5.2...2.6.0) (2024-05-03)


### 📦 Other

* **ci:** update gitlab-ci ([ff0eece](https://gitlab.com/simonoscr/nixfiles/commit/ff0eece96e98e7e47fb08f7cd2ceba2ed53e1181))
* **ci:** update job dependencies ([c0f363e](https://gitlab.com/simonoscr/nixfiles/commit/c0f363eb052d9775c3af4c80327e47033c5a63f9))
* **flake:** update flake.lock ([d26fc6d](https://gitlab.com/simonoscr/nixfiles/commit/d26fc6d830d96e2168abdd889944de315a1308fb))
* **semver:** update releaserc config commit message with scope ([684ead5](https://gitlab.com/simonoscr/nixfiles/commit/684ead5b86db48508223a3e0abbc7bef49fa1747))


### 🦊 CI/CD

* add assets to release ([f507ac3](https://gitlab.com/simonoscr/nixfiles/commit/f507ac329ef5e3e06c3b01a09792777ab23cd0ce))
* fix job typo ([858b8e8](https://gitlab.com/simonoscr/nixfiles/commit/858b8e8e6aa5f2e9dc2161b0a1384d74e4f4ec28))
* test ([319c120](https://gitlab.com/simonoscr/nixfiles/commit/319c12079d3ba3a54c8be213d6e90e54c65238ce))
* update stages ([3eb3912](https://gitlab.com/simonoscr/nixfiles/commit/3eb391224578d18ba1818b53a90ffa58509e6392))


### 🧪 Tests

* remove a nix build install-iso step for testing job ([41265fd](https://gitlab.com/simonoscr/nixfiles/commit/41265fd7f05dc825018c2b2630a4949b1c8e4b58))
* semantic release ([fe59780](https://gitlab.com/simonoscr/nixfiles/commit/fe59780338af3f7afda92cfa05fa7bf5562a8b0c))


### 🚀 Features

* update with iso flake; pipeline update refined semantic-release with gitlab release ([22f88a2](https://gitlab.com/simonoscr/nixfiles/commit/22f88a20e8a5eaed7b9a7df9c6638b82f5134a26))

# Changelog

All notable changes to this project will be documented in this file. See
[Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## [2.5.2](https://gitlab.com/simonoscr/nixfiles/compare/v2.5.1...v2.5.2) (2024-05-01)


### Bug Fixes

* update git for sign commits ([49cc2d7](https://gitlab.com/simonoscr/nixfiles/commit/49cc2d7809625e5bbac2272f8c80d8a8ede2ca50))

## [2.5.1](https://gitlab.com/simonoscr/nixfiles/compare/v2.5.0...v2.5.1) (2024-05-01)


### Bug Fixes

* use virtualisation.nix instead of own podman.nix file ([8a96fd3](https://gitlab.com/simonoscr/nixfiles/commit/8a96fd3f7739e32f583c505b953bee5c62fb7fe1))

## [2.5.0](https://gitlab.com/simonoscr/nixfiles/compare/v2.4.8...v2.5.0) (2024-05-01)


### Features

* **ci:** update pipeline to contains cleanup, lint and tests, add podman ([aff8f58](https://gitlab.com/simonoscr/nixfiles/commit/aff8f582cc42caa5d708e0434c638c94588a0846))

## [2.4.8](https://gitlab.com/simonoscr/nixfiles/compare/v2.4.7...v2.4.8) (2024-05-01)


### Bug Fixes

* update flock and lint ([755a334](https://gitlab.com/simonoscr/nixfiles/commit/755a334aa4f5b98f9ee6ba48f2080056cb1c2453))

## [2.4.7](https://gitlab.com/simonoscr/nixfiles/compare/v2.4.6...v2.4.7) (2024-05-01)


### Bug Fixes

* remove dead code with deadnix ([d640b78](https://gitlab.com/simonoscr/nixfiles/commit/d640b78b4c43c52b758d409fb2fd4ae1263ad2d2))

## [2.4.6](https://gitlab.com/simonoscr/nixfiles/compare/v2.4.5...v2.4.6) (2024-05-01)


### Bug Fixes

* add hy3 hyprland plugin but not activate it and update ([223369d](https://gitlab.com/simonoscr/nixfiles/commit/223369dfbd283571122d78fe7368ddc72bd1925e))

## [2.4.5](https://gitlab.com/simonoscr/nixfiles/compare/v2.4.4...v2.4.5) (2024-04-30)


### Bug Fixes

* add zed hyprland shortcut ([c3ad0d2](https://gitlab.com/simonoscr/nixfiles/commit/c3ad0d229207e711ff7903d590db456c3912a025))

## [2.4.4](https://gitlab.com/simonoscr/nixfiles/compare/v2.4.3...v2.4.4) (2024-04-30)


### Bug Fixes

* add zed editor ([14c3927](https://gitlab.com/simonoscr/nixfiles/commit/14c3927508932fc47676abdba7a8520af9755042))

## [2.4.3](https://gitlab.com/simonoscr/nixfiles/compare/v2.4.2...v2.4.3) (2024-04-30)


### Bug Fixes

* add trusted- and allowed-users; remove chaotix and disable flake input; general update flock ([0e45260](https://gitlab.com/simonoscr/nixfiles/commit/0e452606d2a76ffed7cbb7330ddfac33ae1b600b))

## [2.4.2](https://gitlab.com/simonoscr/nixfiles/compare/v2.4.1...v2.4.2) (2024-04-30)


### Bug Fixes

* cleanup dead code with deadnix ([8856c79](https://gitlab.com/simonoscr/nixfiles/commit/8856c79a85d3e9b359463582e452bc4c23cb88b6))

## [2.4.1](https://gitlab.com/simonoscr/nixfiles/compare/v2.4.0...v2.4.1) (2024-04-29)


### Bug Fixes

* update firefox theme ([a4d12bc](https://gitlab.com/simonoscr/nixfiles/commit/a4d12bc6116480f82bb5bd759fb50d921ad3c6d9))
* update tabbar height ([41e0bbd](https://gitlab.com/simonoscr/nixfiles/commit/41e0bbd3be7f5bc2e36eb0ec700be78a2cf4d9fc))

## [2.4.0](https://gitlab.com/simonoscr/nixfiles/compare/v2.3.4...v2.4.0) (2024-04-29)


### Features

* add nh, update README; update docs ([57402f5](https://gitlab.com/simonoscr/nixfiles/commit/57402f5337ee3e18e0e57498965c873bd02fee02))

## [2.3.4](https://gitlab.com/simonoscr/nixfiles/compare/v2.3.3...v2.3.4) (2024-04-29)


### Bug Fixes

* update flock; hyprland sens and move libinput from services.xserver to services ([65c1ba7](https://gitlab.com/simonoscr/nixfiles/commit/65c1ba7e0703d264d3d95c9c30a48b6d6407e9a8))

## [2.3.3](https://gitlab.com/simonoscr/nixfiles/compare/v2.3.2...v2.3.3) (2024-04-28)


### Bug Fixes

* update hyprland config sens ([ead5ac7](https://gitlab.com/simonoscr/nixfiles/commit/ead5ac7ff415a60112e99f2dbd24673aa35778e4))

## [2.3.2](https://gitlab.com/simonoscr/nixfiles/compare/v2.3.1...v2.3.2) (2024-04-28)


### Bug Fixes

* update lock and firefox settings to open bookmarks in new tab ([e603407](https://gitlab.com/simonoscr/nixfiles/commit/e6034075c2a51f94b3a2015a2fc1b159fc27ff70))

## [2.3.1](https://gitlab.com/simonoscr/nixfiles/compare/v2.3.0...v2.3.1) (2024-04-27)


### Bug Fixes

* add globalshortcuts to hyprland for ts3; add media key shortcuts; update mangohud config ([8204343](https://gitlab.com/simonoscr/nixfiles/commit/820434393c45f1dad64ad3853061ba1c167d6e07))

## [2.3.0](https://gitlab.com/simonoscr/nixfiles/compare/v2.2.0...v2.3.0) (2024-04-24)


### Features

* big update nixos, hyprland ([5e35450](https://gitlab.com/simonoscr/nixfiles/commit/5e3545087c123a8c3650e15742e47af43c99c9cb))

## [2.2.0](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.28...v2.2.0) (2024-04-07)


### Features

* docs; cleanup and pump minor after ref ([8e2e547](https://gitlab.com/simonoscr/nixfiles/commit/8e2e547306aa74aef2136bbe20987575afed47c5))

## [2.1.28](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.27...v2.1.28) (2024-04-06)


### Bug Fixes

* cleanup; remove unused and doubled configs, options, servvices etc ([b02fc0f](https://gitlab.com/simonoscr/nixfiles/commit/b02fc0faf1a6a04ab6656b4a9bfc53b42f325268))

## [2.1.27](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.26...v2.1.27) (2024-04-06)


### Bug Fixes

* add protonmail-desktop beta app ([37e275c](https://gitlab.com/simonoscr/nixfiles/commit/37e275c79077a488ddfce4c8f79ab8f63ff44dfb))

## [2.1.26](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.25...v2.1.26) (2024-04-06)


### Bug Fixes

* add matugen and update flake input ([608fb7c](https://gitlab.com/simonoscr/nixfiles/commit/608fb7ccb55c6a459aaeff1457b3569f6ff93335))

## [2.1.25](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.24...v2.1.25) (2024-04-01)


### Bug Fixes

* reduce audio latency ([a65b0ea](https://gitlab.com/simonoscr/nixfiles/commit/a65b0ea910ad0b5c490efc60a0d229ecba7fde3a))

## [2.1.24](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.23...v2.1.24) (2024-03-31)


### Bug Fixes

* firefox icons ([db79fca](https://gitlab.com/simonoscr/nixfiles/commit/db79fcad98d7ffe0ac0199ee5e07970268942f40))

## [2.1.23](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.22...v2.1.23) (2024-03-31)


### Bug Fixes

* firefox custom icons ([a882322](https://gitlab.com/simonoscr/nixfiles/commit/a882322530322ba9a0e8a245efc4f06c939e3591))

## [2.1.22](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.21...v2.1.22) (2024-03-31)


### Bug Fixes

* firefox autohide tabs ([dbdf2d0](https://gitlab.com/simonoscr/nixfiles/commit/dbdf2d0d2d93f63ae739145c9d60fcb7a7446b9e))

## [2.1.21](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.20...v2.1.21) (2024-03-31)


### Bug Fixes

* update firefox theme ([ba054da](https://gitlab.com/simonoscr/nixfiles/commit/ba054da95a1366130cbe1fc94622637de4d6c2d9))

## [2.1.20](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.19...v2.1.20) (2024-03-31)


### Bug Fixes

* add firefox custom css theme ([99fe78e](https://gitlab.com/simonoscr/nixfiles/commit/99fe78e9bb44115ef43e861b70867e6e4590ece0))

## [2.1.19](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.18...v2.1.19) (2024-03-30)


### Bug Fixes

* remove custom bezier from hyprland use default ([25120c7](https://gitlab.com/simonoscr/nixfiles/commit/25120c7a500a3d5400f78bac38f09a0cc35ec2d1))

## [2.1.18](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.17...v2.1.18) (2024-03-30)


### Bug Fixes

* some hyprland config settings ([9e218e6](https://gitlab.com/simonoscr/nixfiles/commit/9e218e6f181e8e273e30e03c9d7aa755616fca1f))

## [2.1.17](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.16...v2.1.17) (2024-03-30)


### Bug Fixes

* hyprland mouse focus behaviour ([784747b](https://gitlab.com/simonoscr/nixfiles/commit/784747b5c43af8acf39b3cccc417090787975e11))

## [2.1.16](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.15...v2.1.16) (2024-03-30)


### Bug Fixes

* disable bugged hyprland plugin - no auto updating headers when updating hyprland; neovim optionchange from options to opts; copyKernels; remove kvm-amd virtualisation from kernelModules -> not used; enableAllFirmware; update flock ([9fe5986](https://gitlab.com/simonoscr/nixfiles/commit/9fe5986278dbf9a9a886ca4617bda584725754e9))

## [2.1.15](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.14...v2.1.15) (2024-03-29)


### Bug Fixes

* add user to corectrl group for not entering password on startup ([3dc31f3](https://gitlab.com/simonoscr/nixfiles/commit/3dc31f3abad12b779994c66444b52c8a298c04e4))

## [2.1.14](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.13...v2.1.14) (2024-03-29)


### Bug Fixes

* enable hyprland plugins; mangohud config ([379f8bb](https://gitlab.com/simonoscr/nixfiles/commit/379f8bbf7ef6d76ed1b3e956d4863ca2636a71e0))

## [2.1.13](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.12...v2.1.13) (2024-03-29)


### Bug Fixes

* update mouse and focus behavior for hyprland ([b6b3883](https://gitlab.com/simonoscr/nixfiles/commit/b6b3883f7724059598bc156ebbf0cef27aaabdf7))

## [2.1.12](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.11...v2.1.12) (2024-03-29)


### Bug Fixes

* steam with proton-ge-bin extra package; update fonts; update flock ([761efcf](https://gitlab.com/simonoscr/nixfiles/commit/761efcf741fd4fa100536c10dfd6b64f64a4c9eb))

## [2.1.11](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.10...v2.1.11) (2024-03-28)


### Bug Fixes

* update sysctl configuration ([284a076](https://gitlab.com/simonoscr/nixfiles/commit/284a07638df430273d53691fa08aed6f4e1f48fe))

## [2.1.10](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.9...v2.1.10) (2024-03-28)


### Bug Fixes

* add mangohud.nix and configuration; update flock; remove unused pkgs ([685d76f](https://gitlab.com/simonoscr/nixfiles/commit/685d76fb0e5ac40e2e33835588c8081a399547f0))

## [2.1.9](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.8...v2.1.9) (2024-03-24)


### Bug Fixes

* update flock; remove unused inputs; disable watchdog; set RADV variables for gaming performance ([910caaf](https://gitlab.com/simonoscr/nixfiles/commit/910caafd79e6d7bea193de619bfb780bbf741e5c))

## [2.1.8](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.7...v2.1.8) (2024-03-23)


### Bug Fixes

* ags applauncher to launcher; wine waylandFull; cachix for nix-gaming; star-citizen from nix-gaming ([a8a5b91](https://gitlab.com/simonoscr/nixfiles/commit/a8a5b916a49cf627801fbfa64828444c1bfbfb94))

## [2.1.7](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.6...v2.1.7) (2024-03-22)


### Bug Fixes

* update ags ([9075e29](https://gitlab.com/simonoscr/nixfiles/commit/9075e294867281155cc2dc470e1cc365e4e8dcf8))

## [2.1.6](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.5...v2.1.6) (2024-03-22)


### Bug Fixes

* update sysctl congestion_control to BRR ([1e9d2ac](https://gitlab.com/simonoscr/nixfiles/commit/1e9d2ac427f9bb71836fdfa0433a82707d5fc587))

## [2.1.5](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.4...v2.1.5) (2024-03-22)


### Bug Fixes

* ags preventing tearing on fullscreen application so idsable when switching to "gaming"-resolution; update flock ([9268ba7](https://gitlab.com/simonoscr/nixfiles/commit/9268ba700596a3122ade8c89ba37ef2765017286))

## [2.1.4](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.3...v2.1.4) (2024-03-21)


### Bug Fixes

* make tearing under hyprland work (ags bar was the problem) ([9a440a7](https://gitlab.com/simonoscr/nixfiles/commit/9a440a74a870fbddb3e29c18405184be04d6aff4))


### Reverts

* switch to xanmod 6.7.9 instead of latest 6.8.1; remove useless extraLibraries from steam; enable lowLatency pipewire; enable tearing in hyprland ([ca89e62](https://gitlab.com/simonoscr/nixfiles/commit/ca89e62eac893eb7e0f4ceb857aff2b430e92af4))

## [2.1.3](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.2...v2.1.3) (2024-03-19)


### Bug Fixes

* update at switch linux kernel to latest 6.8.1 ([fa538cd](https://gitlab.com/simonoscr/nixfiles/commit/fa538cd7450e4a1737cfca07a7b1b0f159abf34f))

## [2.1.2](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.1...v2.1.2) (2024-03-17)


### Bug Fixes

* update flock and small fixes to adapt to nixpkgs changes ([cb8cd4e](https://gitlab.com/simonoscr/nixfiles/commit/cb8cd4e623ceb74742350ce5c781c1b3002fee42))

## [2.1.1](https://gitlab.com/simonoscr/nixfiles/compare/v2.1.0...v2.1.1) (2024-03-15)


### Bug Fixes

* steam extraCompatPackages see https://github.com/fufexan/nix-gaming/issues/163 ([f721f2a](https://gitlab.com/simonoscr/nixfiles/commit/f721f2afa5d990ab43746d32ace97c1287eeee93))

## [2.1.0](https://gitlab.com/simonoscr/nixfiles/compare/v2.0.2...v2.1.0) (2024-03-05)


### Features

* update ags; restrcture for server voyager ([6654e8a](https://gitlab.com/simonoscr/nixfiles/commit/6654e8a58fd320b3ecf0456581e1a41676fa4e51))

## [2.0.2](https://gitlab.com/simonoscr/nixfiles/compare/v2.0.1...v2.0.2) (2024-03-02)


### Bug Fixes

* correct size for cursor ([c27d530](https://gitlab.com/simonoscr/nixfiles/commit/c27d530dcaa97767acfcf1e1252bf5009246dde0))

## [2.0.1](https://gitlab.com/simonoscr/nixfiles/compare/v2.0.0...v2.0.1) (2024-03-02)


### Bug Fixes

* **finally:** capitaine cursor; wrong size was set ([b8f6a1d](https://gitlab.com/simonoscr/nixfiles/commit/b8f6a1d2f8fce22658562c46dee7c333e9a051de))

## [2.0.0](https://gitlab.com/simonoscr/nixfiles/compare/v1.6.9...v2.0.0) (2024-03-02)


### ⚠ BREAKING CHANGES

* restructure repository for clear structure between home-manager(user scope) and nixos(system scope)

### Code Refactoring

* reorganize nixfiles to make more clear what is home-manager and what nix/nixos ([9d1e349](https://gitlab.com/simonoscr/nixfiles/commit/9d1e34986a1712bb0ea38a62a21a50f41264a7c9))

## [1.6.9](https://gitlab.com/simonoscr/nixfiles/compare/v1.6.8...v1.6.9) (2024-03-02)


### Bug Fixes

* hyprlock settings and shortcut, remove swaylock pam ([240f92a](https://gitlab.com/simonoscr/nixfiles/commit/240f92a6a9c97858bc98d9eb4cdaa8c8bfa56aef))

## [1.6.8](https://gitlab.com/simonoscr/nixfiles/compare/v1.6.7...v1.6.8) (2024-03-02)


### Bug Fixes

* switched from swaylock+swayidle to hyprlock+hypridle ([555097a](https://gitlab.com/simonoscr/nixfiles/commit/555097a28113476d0ebccaf1ab621e22385e16cc))

## [1.6.7](https://gitlab.com/simonoscr/nixfiles/compare/v1.6.6...v1.6.7) (2024-03-02)


### Bug Fixes

* example of adding knownHosts (but not for user) ([e5dbc4a](https://gitlab.com/simonoscr/nixfiles/commit/e5dbc4ad221466d5b06389eb1275193949d2cc34))

## [1.6.6](https://gitlab.com/simonoscr/nixfiles/compare/v1.6.5...v1.6.6) (2024-03-02)


### Bug Fixes

* change path to secrets ([131276e](https://gitlab.com/simonoscr/nixfiles/commit/131276e6fe5109d062f0cbcfc88e53df7adb5117))

## [1.6.5](https://gitlab.com/simonoscr/nixfiles/compare/v1.6.4...v1.6.5) (2024-03-02)


### Bug Fixes

* TERM user sessionsenv ([f1fe203](https://gitlab.com/simonoscr/nixfiles/commit/f1fe203209623e0e42f1d1dba6e0937e3c140bb6))

## [1.6.4](https://gitlab.com/simonoscr/nixfiles/compare/v1.6.3...v1.6.4) (2024-03-02)


### Bug Fixes

* update voyager and flock ([3f95ddb](https://gitlab.com/simonoscr/nixfiles/commit/3f95ddb755d558da56a812b300a0c79256a67d0e))

## [1.6.3](https://gitlab.com/simonoscr/nixfiles/compare/v1.6.2...v1.6.3) (2024-02-29)


### Bug Fixes

* add bookmark ([518df6d](https://gitlab.com/simonoscr/nixfiles/commit/518df6d6e56f9bb1cb03825d9c111f26e29c02b0))

## [1.6.2](https://gitlab.com/simonoscr/nixfiles/compare/v1.6.1...v1.6.2) (2024-02-29)


### Bug Fixes

* pipewire config anf update flock ([23d05bf](https://gitlab.com/simonoscr/nixfiles/commit/23d05bf679bd42577d41d2ccd2d23f0d22384b35))

## [1.6.1](https://gitlab.com/simonoscr/nixfiles/compare/v1.6.0...v1.6.1) (2024-02-28)


### Bug Fixes

* update and fix pipewire configuration. environment.etc not possible anymore. ([513f635](https://gitlab.com/simonoscr/nixfiles/commit/513f635d6cafdefc43627bbadb8d89875d9300b1))

## [1.6.0](https://gitlab.com/simonoscr/nixfiles/compare/v1.5.7...v1.6.0) (2024-02-25)


### Features

* update flock; big nixpkgs merge staging-next to nixos-unstable ([0bf7f1d](https://gitlab.com/simonoscr/nixfiles/commit/0bf7f1d88ab380db728afbcbcb0f07a3567a9220))

## [1.5.7](https://gitlab.com/simonoscr/nixfiles/compare/v1.5.6...v1.5.7) (2024-02-24)


### Bug Fixes

* update and switch kernel ([3e1bc71](https://gitlab.com/simonoscr/nixfiles/commit/3e1bc710d23cff724cff4a70c612396766571a61))
* update kernel again to xanmod 6.7.5; add kernel.sysctl parameter for low latency; and add inputs ([a84d019](https://gitlab.com/simonoscr/nixfiles/commit/a84d019d6f3a638c2541f6de5ee28a76a84b6772))

## [1.5.6](https://gitlab.com/simonoscr/nixfiles/compare/v1.5.5...v1.5.6) (2024-02-23)


### Bug Fixes

* open steam and webcord always on workspace 2 ([c05765c](https://gitlab.com/simonoscr/nixfiles/commit/c05765cff20209ff4513112d8aeb039745b152c1))

## [1.5.5](https://gitlab.com/simonoscr/nixfiles/compare/v1.5.4...v1.5.5) (2024-02-23)


### Bug Fixes

* disable waybar and update flock ([2eb6054](https://gitlab.com/simonoscr/nixfiles/commit/2eb605422feee92ea818f37c920501ef60939413))
* return back to original ags ([c0e8b53](https://gitlab.com/simonoscr/nixfiles/commit/c0e8b533d12672034f9b4c9938fe72eb97ff530a))

## [1.5.4](https://gitlab.com/simonoscr/nixfiles/compare/v1.5.3...v1.5.4) (2024-02-23)


### Bug Fixes

* switch to latest (6.7.5) xanmod kernel ([cf1b685](https://gitlab.com/simonoscr/nixfiles/commit/cf1b685ec7f110a7a2a3eec30acd9b35727470c5))

## [1.5.3](https://gitlab.com/simonoscr/nixfiles/compare/v1.5.2...v1.5.3) (2024-02-23)


### Bug Fixes

* add piper ([58df67d](https://gitlab.com/simonoscr/nixfiles/commit/58df67dd3b023200a8319acb0074d99fe73eca09))

## [1.5.2](https://gitlab.com/simonoscr/nixfiles/compare/v1.5.1...v1.5.2) (2024-02-22)


### Bug Fixes

* remove sops-nix from repo ([cf71e27](https://gitlab.com/simonoscr/nixfiles/commit/cf71e2746e563a11a31380e98767103378d53a75))

## [1.5.1](https://gitlab.com/simonoscr/nixfiles/compare/v1.5.0...v1.5.1) (2024-02-22)


### Bug Fixes

* disable firefox containers ([01d6ec1](https://gitlab.com/simonoscr/nixfiles/commit/01d6ec1e0f2b0c7db155abe8811df308ec20705d))

## [1.5.0](https://gitlab.com/simonoscr/nixfiles/compare/v1.4.11...v1.5.0) (2024-02-21)


### Features

* update flock; disable nixpkgs-wayland flake input; docs; i3 configuration; polybar ([72b20ec](https://gitlab.com/simonoscr/nixfiles/commit/72b20ec0369e9945af47b02a917840371bd09c60))

## [1.4.11](https://gitlab.com/simonoscr/nixfiles/compare/v1.4.10...v1.4.11) (2024-02-19)


### Bug Fixes

* idk ([6e1774b](https://gitlab.com/simonoscr/nixfiles/commit/6e1774b3a088efbba549025495cca4a6e593263a))

## [1.4.10](https://gitlab.com/simonoscr/nixfiles/compare/v1.4.9...v1.4.10) (2024-02-19)


### Bug Fixes

* switch to xanmod_latest kernel; add loginLimits; stylix settings; hyprland config ([9405e94](https://gitlab.com/simonoscr/nixfiles/commit/9405e94078f662d9b03edb69026626f86c304bdf))

## [1.4.9](https://gitlab.com/simonoscr/nixfiles/compare/v1.4.8...v1.4.9) (2024-02-17)


### Bug Fixes

* ref graphics to hardware.nix; add udiskie for auto mount sb sticks; set sysctl settings like increase zram swap; max_m ap_count and page-cluster ([251bf9e](https://gitlab.com/simonoscr/nixfiles/commit/251bf9e25e5821a4a9c8cc7a67d35c728898cdc5))

## [1.4.8](https://gitlab.com/simonoscr/nixfiles/compare/v1.4.7...v1.4.8) (2024-02-17)


### Bug Fixes

* add dunst.nix, adjust hyprland plugin settings; move home-packages to hyprland default.nix, update flock ([ea5542b](https://gitlab.com/simonoscr/nixfiles/commit/ea5542bd7dbd9bab16b4e8a6dc0b35e0fd2b28d6))

## [1.4.7](https://gitlab.com/simonoscr/nixfiles/compare/v1.4.6...v1.4.7) (2024-02-16)


### Bug Fixes

* keep website settings in firefox ([24cc88c](https://gitlab.com/simonoscr/nixfiles/commit/24cc88c08b836ec52bcda78e9207994ba3c63c26))

## [1.4.6](https://gitlab.com/simonoscr/nixfiles/compare/v1.4.5...v1.4.6) (2024-02-16)


### Bug Fixes

* gamemode CAPs; hyprland config window rules ([0398306](https://gitlab.com/simonoscr/nixfiles/commit/0398306bec3d002df254c16d5474cb65dab54952))

## [1.4.5](https://gitlab.com/simonoscr/nixfiles/compare/v1.4.4...v1.4.5) (2024-02-16)


### Bug Fixes

* switch to stylix for applications ([79632d0](https://gitlab.com/simonoscr/nixfiles/commit/79632d0a061d523848a5c2c4e8c34cf61f7fcd96))

## [1.4.4](https://gitlab.com/simonoscr/nixfiles/compare/v1.4.3...v1.4.4) (2024-02-16)


### Bug Fixes

* add AMDVLK pkg but default to RADV; add opencl pkgs ([b306f9b](https://gitlab.com/simonoscr/nixfiles/commit/b306f9b688c9fcc9169b0d701c85b3d590cfa5ac))

## [1.4.3](https://gitlab.com/simonoscr/nixfiles/compare/v1.4.2...v1.4.3) (2024-02-16)


### Bug Fixes

* add user to gamemode group; activate hyprland plugin to fix cs2 4:3 streched with SDL_VIDEO_DRIVER=x11 (wayland not working with this fix); fix hyprland env; move hyprland dependend packages to hyprland; ([181033e](https://gitlab.com/simonoscr/nixfiles/commit/181033ef3991f00418d0d4e5cd4484f1c1a08c1e))

## [1.4.2](https://gitlab.com/simonoscr/nixfiles/compare/v1.4.1...v1.4.2) (2024-02-16)


### Bug Fixes

* update firefox bookmarks and settings ([d04a484](https://gitlab.com/simonoscr/nixfiles/commit/d04a4849eac3a538b761e13942b52ec59ea8c38f))

## [1.4.1](https://gitlab.com/simonoscr/nixfiles/compare/v1.4.0...v1.4.1) (2024-02-15)


### Bug Fixes

* switch firefox pkgs to be able to import bookmarks file; hyprland fixes ([75e3206](https://gitlab.com/simonoscr/nixfiles/commit/75e32060323a520947b92bb515aa6e81764ca983))

## [1.4.0](https://gitlab.com/simonoscr/nixfiles/compare/v1.3.3...v1.4.0) (2024-02-14)


### Features

* add yazi, bat, direnv; added features to security, audio, and shell ([afd848c](https://gitlab.com/simonoscr/nixfiles/commit/afd848c57a9b0ce3fa156d1309d4b3bf54159968))

## [1.3.3](https://gitlab.com/simonoscr/nixfiles/compare/v1.3.2...v1.3.3) (2024-02-13)


### Bug Fixes

* wl env that breaks vscodium ([57ba1d2](https://gitlab.com/simonoscr/nixfiles/commit/57ba1d213e72ac75feaf29847df70c2a7e349348))

## [1.3.2](https://gitlab.com/simonoscr/nixfiles/compare/v1.3.1...v1.3.2) (2024-02-12)


### Bug Fixes

* small fixes in audio like removed unused pkgs; ([421c503](https://gitlab.com/simonoscr/nixfiles/commit/421c503ecf8b93b56ef73cc1df9d912971ad4c56))

## [1.3.1](https://gitlab.com/simonoscr/nixfiles/compare/v1.3.0...v1.3.1) (2024-02-11)


### Bug Fixes

* small fixes to gaming related things; remove mimeApps; remove unused inputs ([27cfb73](https://gitlab.com/simonoscr/nixfiles/commit/27cfb735fa236f95c29aec6a71db17caa1c13525))

## [1.3.0](https://gitlab.com/simonoscr/nixfiles/compare/v1.2.1...v1.3.0) (2024-02-11)


### Features

* switch kernel to linux_latest (6.7); use mesa-git (24.0); remove unused programs; cleanup code; add corectrl as program, activate OC for AMD GPU ([e7975cf](https://gitlab.com/simonoscr/nixfiles/commit/e7975cfba16a9fb2b40ee7528d2d198e71c87b00))

## [1.2.1](https://gitlab.com/simonoscr/nixfiles/compare/v1.2.0...v1.2.1) (2024-02-10)


### Bug Fixes

* restructure sops-nix ([7c3a146](https://gitlab.com/simonoscr/nixfiles/commit/7c3a14699a11c98fe6a5ceac726964b3affc599a))

## [1.2.0](https://gitlab.com/simonoscr/nixfiles/compare/v1.1.0...v1.2.0) (2024-02-09)


### Features

* **cosmos:** switch to home-manager module from standalone for cosmos host and fix some configuration problems ([0024eb1](https://gitlab.com/simonoscr/nixfiles/commit/0024eb1602fa3f763106a4d38e50e957ef8e5506))

## [1.1.0](https://gitlab.com/simonoscr/nixfiles/compare/v1.0.2...v1.1.0) (2024-02-09)


### Features

* add home-manager as a module to cosmos and remove standalone-hm config ([2a61f8f](https://gitlab.com/simonoscr/nixfiles/commit/2a61f8f221d05e8de217f69bc60f8b95f7579691))

## [1.0.2](https://gitlab.com/simonoscr/nixfiles/compare/v1.0.1...v1.0.2) (2024-02-09)


### Bug Fixes

* simples things in hyprland; manage game related dependencies and doc ([6f978b6](https://gitlab.com/simonoscr/nixfiles/commit/6f978b65764d57726c6e264af330d479d33e726b))

## [1.0.1](https://gitlab.com/simonoscr/nixfiles/compare/v1.0.0...v1.0.1) (2024-02-09)


### Bug Fixes

* hardware configurations and gaming related updates and tests ([bfbfe11](https://gitlab.com/simonoscr/nixfiles/commit/bfbfe115ffde43913c53a096c9af9e5c8ebcd6c9))
* nixvim structure update ([89b1350](https://gitlab.com/simonoscr/nixfiles/commit/89b135019e94688ca1bbf1c66f25efaa9d27a794))

## 1.0.0 (2024-02-08)


### Bug Fixes

* moce gamescope to home-manager package ([be954c3](https://gitlab.com/simonoscr/nixfiles/commit/be954c3bc656b26615a4751fb09e6fcaf22ad9d8))
* README center nixos ([8277bb6](https://gitlab.com/simonoscr/nixfiles/commit/8277bb64371e75c1f3a812ffbcf66d6bd26c9c69))
* remove docker pull from image reference in semver stage ([4619a2a](https://gitlab.com/simonoscr/nixfiles/commit/4619a2add8675315ed064fcb7e5fe4ee06f365c2))


############################################
########### MOVED TO GITLAB ################
############################################

## [1.8.12](https://github.com/simonoscr/dotfiles/compare/1.8.11...1.8.12) (2024-02-07)


### Bug Fixes

* theming and update flock ([d19eb3a](https://github.com/simonoscr/dotfiles/commit/d19eb3a3276d040bcd7aa61569d932aaaade39c2))



## [1.8.11](https://github.com/simonoscr/dotfiles/compare/1.8.10...1.8.11) (2024-02-06)


### Bug Fixes

* disable mesa-git ([a03a9a3](https://github.com/simonoscr/dotfiles/commit/a03a9a31236d962ea90cdcccc48fea77b74d3359))



## [1.8.10](https://github.com/simonoscr/dotfiles/compare/1.8.9...1.8.10) (2024-02-06)


### Bug Fixes

* update flock; add chaotic nyx and activate mesa-git ([27e5b3c](https://github.com/simonoscr/dotfiles/commit/27e5b3c50f3dd4664600683db80b732e7264e3d8))



## [1.8.9](https://github.com/simonoscr/dotfiles/compare/1.8.8...1.8.9) (2024-02-04)


### Bug Fixes

* disable SDL_VIDEO_DRIVER=wayland ([81d3440](https://github.com/simonoscr/dotfiles/commit/81d3440f15a31c3a253f0ed85696ef67ffa4ef2b))



## [1.8.8](https://github.com/simonoscr/dotfiles/compare/1.8.7...1.8.8) (2024-02-04)


### Bug Fixes

* update dashy and hyprland config (enable SDL_VIDE_DRIVER ([181af60](https://github.com/simonoscr/dotfiles/commit/181af600b37de4d0438325d6b416d2c6ce109f27))
* volume mount for puhole ([ad375f1](https://github.com/simonoscr/dotfiles/commit/ad375f17a8a97ea9ed453c8d3c65a0135f285e96))



## [1.8.7](https://github.com/simonoscr/dotfiles/compare/1.8.6...1.8.7) (2024-02-04)


### Bug Fixes

* add pihole ([8dea741](https://github.com/simonoscr/dotfiles/commit/8dea741710086e1aa2adbddb1c871562bfd52b5c))



## [1.8.6](https://github.com/simonoscr/dotfiles/compare/1.8.5...1.8.6) (2024-02-04)


### Bug Fixes

* cockpit and dashy ([d28bec1](https://github.com/simonoscr/dotfiles/commit/d28bec117364a76477c9099107b097f4a6dd7a88))
* update dashy, add cockpit and small fixes and updates ([e373d00](https://github.com/simonoscr/dotfiles/commit/e373d00bfeb6b6122742d9f6ec0a3934f6c770ad))



## [1.8.5](https://github.com/simonoscr/dotfiles/compare/1.8.4...1.8.5) (2024-02-04)


### Bug Fixes

* update waybar ([3ff88e7](https://github.com/simonoscr/dotfiles/commit/3ff88e71fbeea0b2c848feaa5d36badab27409af))



## [1.8.4](https://github.com/simonoscr/dotfiles/compare/1.8.3...1.8.4) (2024-02-04)


### Bug Fixes

* customize waybar, scripts and modules and nerd fonts ([894e26a](https://github.com/simonoscr/dotfiles/commit/894e26a765b2c0a79f4f860daa2edbdfc5958aa7))



## [1.8.3](https://github.com/simonoscr/dotfiles/compare/1.8.2...1.8.3) (2024-02-03)


### Bug Fixes

* add i3 shortcuts ([cb0a23c](https://github.com/simonoscr/dotfiles/commit/cb0a23c60ab3692a394a93d14e88b4b35d778a23))
* fix shortcuts and modifier ([5c6c369](https://github.com/simonoscr/dotfiles/commit/5c6c36942ff3c07ad538b4cde7bf650fa7387b72))



## [1.8.2](https://github.com/simonoscr/dotfiles/compare/1.8.1...1.8.2) (2024-02-03)


### Bug Fixes

* add i3, polybar, hyprland fixes, waybar, fixes ([3d68d38](https://github.com/simonoscr/dotfiles/commit/3d68d38744135c42c4dba37bd5ac46ac19d36030))



## [1.8.1](https://github.com/simonoscr/dotfiles/compare/1.8.0...1.8.1) (2024-02-03)


### Bug Fixes

* hyprland floating window rule ([d667238](https://github.com/simonoscr/dotfiles/commit/d66723804c1a3b36f596fe4025ca86153feb3ea4))



# [1.8.0](https://github.com/simonoscr/dotfiles/compare/1.7.10...1.8.0) (2024-02-03)


### Features

* use waybar instead of ags (broken), and add: wofi, rofi, wlogout ([8cfde20](https://github.com/simonoscr/dotfiles/commit/8cfde2068df924e55266f87af4c40187729c140a))



## [1.7.10](https://github.com/simonoscr/dotfiles/compare/1.7.9...1.7.10) (2024-02-03)


### Bug Fixes

* loki, dashy, packages, etc ([7a2f5df](https://github.com/simonoscr/dotfiles/commit/7a2f5df5d83932caaed93cc1472332c248bc329b))



## [1.7.9](https://github.com/simonoscr/dotfiles/compare/1.7.8...1.7.9) (2024-02-02)


### Bug Fixes

* add extension ([8e52dd6](https://github.com/simonoscr/dotfiles/commit/8e52dd6864598ec45837717372f0a3556b6bc41e))



## [1.7.8](https://github.com/simonoscr/dotfiles/compare/1.7.7...1.7.8) (2024-02-02)


### Bug Fixes

* remove nslookup and add dig ([693de8a](https://github.com/simonoscr/dotfiles/commit/693de8ab326e74e39d31083183eb6d3c36e9c3a4))



## [1.7.7](https://github.com/simonoscr/dotfiles/compare/1.7.6...1.7.7) (2024-02-02)


### Bug Fixes

* slim home-manager for server ([1bdbfe2](https://github.com/simonoscr/dotfiles/commit/1bdbfe2e29a790514f84e1c97b63b3244c662ac4))



## [1.7.6](https://github.com/simonoscr/dotfiles/compare/1.7.5...1.7.6) (2024-02-02)


### Bug Fixes

* vscodium extensions, firefox bookmarks ([4bc97dd](https://github.com/simonoscr/dotfiles/commit/4bc97dd13bc94adc6c613873acfea3843eb510f8))



## [1.7.5](https://github.com/simonoscr/dotfiles/compare/1.7.4...1.7.5) (2024-02-02)


### Bug Fixes

* add autoUpgrade to voyager ([a304b7c](https://github.com/simonoscr/dotfiles/commit/a304b7c512c74f902f6e76f88bc12d8578296122))



## [1.7.4](https://github.com/simonoscr/dotfiles/compare/1.7.3...1.7.4) (2024-02-02)


### Bug Fixes

* update firefox bookmarks and locale ([94373d7](https://github.com/simonoscr/dotfiles/commit/94373d73c64f87d99f1ec58a1df68c7b2280658e))



## [1.7.3](https://github.com/simonoscr/dotfiles/compare/1.7.2...1.7.3) (2024-02-02)


### Bug Fixes

* unbound logs and metrics and grafana dashboard ([90cc147](https://github.com/simonoscr/dotfiles/commit/90cc147aa62199a3e87861f0e08102de4d7efcb2))



## [1.7.2](https://github.com/simonoscr/dotfiles/compare/1.7.1...1.7.2) (2024-02-02)


### Bug Fixes

* add kanidm ([3c2d282](https://github.com/simonoscr/dotfiles/commit/3c2d282a12518ab925e78fd6c562dd348e303f43))
* add pam auth to applications ([0da792b](https://github.com/simonoscr/dotfiles/commit/0da792bf32b634ebf2f821ad17f94c8cbd93af4a))



## [1.7.1](https://github.com/simonoscr/dotfiles/compare/1.7.0...1.7.1) (2024-02-02)


### Bug Fixes

* add logs to unbound ([59044eb](https://github.com/simonoscr/dotfiles/commit/59044eb8008227e0bf15f5a872489eb9807c2fac))
* fix unbound exporter ([e786e95](https://github.com/simonoscr/dotfiles/commit/e786e95caa44ccd10d76ac703c063f92fd751839))



# [1.7.0](https://github.com/simonoscr/dotfiles/compare/1.6.12...1.7.0) (2024-02-02)


### Features

* add unbound as local DNS, use local DNS for monitoring stack, add grafana dashboards ([2587d4c](https://github.com/simonoscr/dotfiles/commit/2587d4c710e2f47ef9723f48cb28c11893f71bbf))



## [1.6.12](https://github.com/simonoscr/dotfiles/compare/1.6.11...1.6.12) (2024-01-29)


### Bug Fixes

* update network etc add openldap and kanidm ([8fa1895](https://github.com/simonoscr/dotfiles/commit/8fa1895d69fca570a5206aae1154efaf672d7636))



## [1.6.11](https://github.com/simonoscr/dotfiles/compare/1.6.10...1.6.11) (2024-01-29)


### Bug Fixes

* add unbound, networking and update ([283ffd1](https://github.com/simonoscr/dotfiles/commit/283ffd1f637fa247187a1ee8e039cc7f2d9ddbba))
* update local dns ([a79e267](https://github.com/simonoscr/dotfiles/commit/a79e267fa2d13475d57a423cda665f6f90432b29))



## [1.6.10](https://github.com/simonoscr/dotfiles/compare/1.6.9...1.6.10) (2024-01-28)


### Bug Fixes

* monitoring stack ([af54d73](https://github.com/simonoscr/dotfiles/commit/af54d73ac98114c92fb5504b2a1192398c77dead))



## [1.6.9](https://github.com/simonoscr/dotfiles/compare/1.6.8...1.6.9) (2024-01-28)


### Bug Fixes

* monitoring stack update with prometheus, loki, node-exporter, promtail, granfana and nginx ([5658f35](https://github.com/simonoscr/dotfiles/commit/5658f35a4951550bd4d4bc64794c66c4480a5f2f))
* update monitoring and logging stack ([4c2b580](https://github.com/simonoscr/dotfiles/commit/4c2b580c9f8a92203ac746cb6d7e6a732625a208))



## [1.6.8](https://github.com/simonoscr/dotfiles/compare/1.6.7...1.6.8) (2024-01-28)


### Bug Fixes

* configure grafana with datasource and node dashboard ([e2ff290](https://github.com/simonoscr/dotfiles/commit/e2ff2908407e87979d202966679b5a88e9397736))



## [1.6.7](https://github.com/simonoscr/dotfiles/compare/1.6.6...1.6.7) (2024-01-28)


### Bug Fixes

* update hardware-configuration.nix ([cd83841](https://github.com/simonoscr/dotfiles/commit/cd8384117c4fc854c9d9f6c6175685645069411e))



## [1.6.6](https://github.com/simonoscr/dotfiles/compare/1.6.5...1.6.6) (2024-01-28)


### Bug Fixes

* update vaultwarden ip ([ae8cf3c](https://github.com/simonoscr/dotfiles/commit/ae8cf3c2f993d48bf554d568e96a1d73b1a2504b))



## [1.6.5](https://github.com/simonoscr/dotfiles/compare/1.6.4...1.6.5) (2024-01-28)


### Bug Fixes

* add userhome directory ([1634274](https://github.com/simonoscr/dotfiles/commit/163427421b5362a24f8702cce642f66b40501e92))



## [1.6.4](https://github.com/simonoscr/dotfiles/compare/1.6.3...1.6.4) (2024-01-28)


### Bug Fixes

* update home.manager user for server ([30e23fe](https://github.com/simonoscr/dotfiles/commit/30e23fe939ce06ab5e7fe65193ea768ea0f56af7))



## [1.6.3](https://github.com/simonoscr/dotfiles/compare/1.6.2...1.6.3) (2024-01-28)


### Bug Fixes

* update ([1cbe18c](https://github.com/simonoscr/dotfiles/commit/1cbe18c26f18d4d563ec5927901a69412af480bc))
* update age key ([d842996](https://github.com/simonoscr/dotfiles/commit/d84299666dba5d432c9cbadf3b0011aa09dddb34))
* update sshd ([1be4ae9](https://github.com/simonoscr/dotfiles/commit/1be4ae9095319bfde0835515cc5d6edc70ca308a))



## [1.6.2](https://github.com/simonoscr/dotfiles/compare/1.6.1...1.6.2) (2024-01-28)


### Bug Fixes

* update docs and first installation process ([65a44ee](https://github.com/simonoscr/dotfiles/commit/65a44eeb6682e7ac3d051163dba0cf29867c2c4f))



## [1.6.1](https://github.com/simonoscr/dotfiles/compare/1.6.0...1.6.1) (2024-01-24)


### Bug Fixes

* update zsh aliases, add podman ([ea4db23](https://github.com/simonoscr/dotfiles/commit/ea4db23f6efdf9cd981a9aac2aaa25c9caec9b81))



# [1.6.0](https://github.com/simonoscr/dotfiles/compare/1.5.17...1.6.0) (2024-01-24)


### Features

* add monitoring stack ([40d8bf0](https://github.com/simonoscr/dotfiles/commit/40d8bf028c092efd15e142c49b4bb2b343ebd554))
* add prometheus, grafana, node exporter, vaultwarden and reverse-proxy to voyager ([e373954](https://github.com/simonoscr/dotfiles/commit/e3739544eea2747b300531d5860f5e5a3ba53e66))



## [1.5.17](https://github.com/simonoscr/dotfiles/compare/1.5.16...1.5.17) (2024-01-22)


### Bug Fixes

* hashedpassword for user ([a26fa82](https://github.com/simonoscr/dotfiles/commit/a26fa825f787c077ffc020c005fafc96a9f3ce5b))



## [1.5.16](https://github.com/simonoscr/dotfiles/compare/1.5.15...1.5.16) (2024-01-21)


### Bug Fixes

* typo ([4d9b473](https://github.com/simonoscr/dotfiles/commit/4d9b473cce7347fbeda366d8f2f30eaa785eecc1))
* update security, network and user files ([5fa4eb1](https://github.com/simonoscr/dotfiles/commit/5fa4eb153dbdca0fc42518a109041703471c6b9e))



## [1.5.15](https://github.com/simonoscr/dotfiles/compare/1.5.14...1.5.15) (2024-01-21)


### Bug Fixes

* revert openssh settings ([77e4a55](https://github.com/simonoscr/dotfiles/commit/77e4a55e7781ccf136136a105d6d469b62328df1))



## [1.5.14](https://github.com/simonoscr/dotfiles/compare/1.5.13...1.5.14) (2024-01-21)


### Bug Fixes

* update user passwords ([e318444](https://github.com/simonoscr/dotfiles/commit/e318444e043277793f00e635c9e584ddc07e1620))



## [1.5.13](https://github.com/simonoscr/dotfiles/compare/1.5.12...1.5.13) (2024-01-21)


### Bug Fixes

* hashedPasswordFile for user password ([1cb14ad](https://github.com/simonoscr/dotfiles/commit/1cb14ad7b15f78962f07594a856fc563260b7bbb))



## [1.5.12](https://github.com/simonoscr/dotfiles/compare/1.5.11...1.5.12) (2024-01-21)


### Bug Fixes

* typo ([f81eea4](https://github.com/simonoscr/dotfiles/commit/f81eea45b7ca15ab2d10e256ecf2f02fe4b43315))
* update passwordfile ([9956a40](https://github.com/simonoscr/dotfiles/commit/9956a407b153dd033fc4fb9d44321a57d21002bf))



## [1.5.11](https://github.com/simonoscr/dotfiles/compare/1.5.10...1.5.11) (2024-01-21)


### Bug Fixes

* neededFor User sops ([c2b664d](https://github.com/simonoscr/dotfiles/commit/c2b664d4086c4e82625bb2cce245501de5ac64bd))
* test user password with sops ([75d569b](https://github.com/simonoscr/dotfiles/commit/75d569b1c7ff68d5f468567a9026c9ef10db57be))



## [1.5.10](https://github.com/simonoscr/dotfiles/compare/1.5.9...1.5.10) (2024-01-21)


### Bug Fixes

* update secrets files with new age key ([edfef64](https://github.com/simonoscr/dotfiles/commit/edfef64e32154b2105de227883ccdd9934b414af))



## [1.5.9](https://github.com/simonoscr/dotfiles/compare/1.5.8...1.5.9) (2024-01-21)


### Bug Fixes

* update home.nix for oscar ([2b5d683](https://github.com/simonoscr/dotfiles/commit/2b5d683b898816bb8737cef17926385b1051ea77))



## [1.5.8](https://github.com/simonoscr/dotfiles/compare/1.5.7...1.5.8) (2024-01-21)


### Bug Fixes

* update home-manager user ([97ed1f3](https://github.com/simonoscr/dotfiles/commit/97ed1f3a79d0951e2836cc971d93db5f36ad94cf))



## [1.5.7](https://github.com/simonoscr/dotfiles/compare/1.5.6...1.5.7) (2024-01-21)


### Bug Fixes

* update sops-nix and secrets files ([ac70a4f](https://github.com/simonoscr/dotfiles/commit/ac70a4ff34f2715a96d42cec134b7cc96a22739b))



## [1.5.6](https://github.com/simonoscr/dotfiles/compare/1.5.5...1.5.6) (2024-01-21)


### Bug Fixes

* update hardware-configuration.nix for server ([fee56d1](https://github.com/simonoscr/dotfiles/commit/fee56d1fb0ff333c67739ab04d5f38001fb041bc))



## [1.5.5](https://github.com/simonoscr/dotfiles/compare/1.5.4...1.5.5) (2024-01-21)


### Bug Fixes

* users and root settings ([ec371e0](https://github.com/simonoscr/dotfiles/commit/ec371e0cb7e430bc1ec01cd92b1641d4c5bd2339))



## [1.5.4](https://github.com/simonoscr/dotfiles/compare/1.5.3...1.5.4) (2024-01-20)


### Bug Fixes

* remove cli.nix from home-manager ([624aefa](https://github.com/simonoscr/dotfiles/commit/624aefa83088d13d67f2b425125f6b515253484a))



## [1.5.3](https://github.com/simonoscr/dotfiles/compare/1.5.2...1.5.3) (2024-01-20)


### Bug Fixes

* update flake for new nixos user ([c33d2ef](https://github.com/simonoscr/dotfiles/commit/c33d2ef13c7d2e5c383290ac36a59bdf0dab357b))



## [1.5.2](https://github.com/simonoscr/dotfiles/compare/1.5.1...1.5.2) (2024-01-20)


### Bug Fixes

* ja ([da8da9b](https://github.com/simonoscr/dotfiles/commit/da8da9b666aad9a902696a345ec586d383b86f2e))



## [1.5.1](https://github.com/simonoscr/dotfiles/compare/1.5.0...1.5.1) (2024-01-20)


### Bug Fixes

* switch to new user ([ace27eb](https://github.com/simonoscr/dotfiles/commit/ace27eb411a20846ce0581acaf75a91119ea476e))



# [1.5.0](https://github.com/simonoscr/dotfiles/compare/1.4.15...1.5.0) (2024-01-20)


### Bug Fixes

* add missing users.nix import ([29006bb](https://github.com/simonoscr/dotfiles/commit/29006bb5ea3d3a2870e01885586e21a9768768ec))
* define group ([2f0fc8e](https://github.com/simonoscr/dotfiles/commit/2f0fc8e7e3879bb0dbc377637bc768f8a30d90a7))
* fix naming of host ([cb0dd17](https://github.com/simonoscr/dotfiles/commit/cb0dd1786446209ed971bcacbcc21ff93193440c))
* fix pathing ([a3928ff](https://github.com/simonoscr/dotfiles/commit/a3928ff435790ebb1b34cf3604139aae046028e7))
* validateSopsFile set to false ([538cdeb](https://github.com/simonoscr/dotfiles/commit/538cdebbb738414307ef37c8635300f0cee4628f))


### Features

* new user.nix to seperate user for services and security ([04a0f0d](https://github.com/simonoscr/dotfiles/commit/04a0f0d130e63ed4d79f50c027575f1a9b166fde))



## [1.4.15](https://github.com/simonoscr/dotfiles/compare/1.4.14...1.4.15) (2024-01-20)


### Bug Fixes

* remo allowSFTP ([cb05706](https://github.com/simonoscr/dotfiles/commit/cb05706f69cc93bb99cf7af9f597d45bf0ef9067))



## [1.4.14](https://github.com/simonoscr/dotfiles/compare/1.4.13...1.4.14) (2024-01-20)


### Bug Fixes

* allowed-user update settings ([24a11fa](https://github.com/simonoscr/dotfiles/commit/24a11faea91973d1c9cb2d68fd1bb00b34d85dcb))



## [1.4.13](https://github.com/simonoscr/dotfiles/compare/1.4.12...1.4.13) (2024-01-20)


### Bug Fixes

* some ssh hardening ([afebcdb](https://github.com/simonoscr/dotfiles/commit/afebcdbd4e91103509eaea0a7163547d3a9333c3))



## [1.4.12](https://github.com/simonoscr/dotfiles/compare/1.4.11...1.4.12) (2024-01-20)


### Bug Fixes

* update mode for secrets ([9e563ea](https://github.com/simonoscr/dotfiles/commit/9e563ea74bf847d68562708c5d9c27e19474a9a8))



## [1.4.11](https://github.com/simonoscr/dotfiles/compare/1.4.10...1.4.11) (2024-01-20)


### Bug Fixes

* add fail2ban ([059956f](https://github.com/simonoscr/dotfiles/commit/059956fd8a7c54b03501af8a237c98f7158caafa))



## [1.4.10](https://github.com/simonoscr/dotfiles/compare/1.4.9...1.4.10) (2024-01-20)


### Bug Fixes

* added configuration for sops-nix ([27619d2](https://github.com/simonoscr/dotfiles/commit/27619d2c6d4a15e0236f886d7153acc42f29b1fd))



## [1.4.9](https://github.com/simonoscr/dotfiles/compare/1.4.8...1.4.9) (2024-01-20)


### Bug Fixes

* zsh as default shell for user host ([9bb89b3](https://github.com/simonoscr/dotfiles/commit/9bb89b35a022736233f165cf31852c6b42b91266))



## [1.4.8](https://github.com/simonoscr/dotfiles/compare/1.4.7...1.4.8) (2024-01-20)


### Bug Fixes

* path for pub key symlink ([5e8fc53](https://github.com/simonoscr/dotfiles/commit/5e8fc539bcf260034cc9b33c50e8b1d394919acc))



## [1.4.7](https://github.com/simonoscr/dotfiles/compare/1.4.6...1.4.7) (2024-01-20)


### Bug Fixes

* authorized_key path ([98b2054](https://github.com/simonoscr/dotfiles/commit/98b2054f367bfa1e24f8d165586c0cf1dbca7689))



## [1.4.6](https://github.com/simonoscr/dotfiles/compare/1.4.5...1.4.6) (2024-01-20)


### Bug Fixes

* add mode for permissions ssh pub key ([1191d68](https://github.com/simonoscr/dotfiles/commit/1191d68f7a9ed6d0111f2f4792108cbf15c35cfa))



## [1.4.5](https://github.com/simonoscr/dotfiles/compare/1.4.4...1.4.5) (2024-01-20)


### Bug Fixes

* permissions ([b06b56b](https://github.com/simonoscr/dotfiles/commit/b06b56b802b117937bb81e1f0d7c8fdfaf67d253))



## [1.4.4](https://github.com/simonoscr/dotfiles/compare/1.4.3...1.4.4) (2024-01-20)


### Bug Fixes

* typo ([94b54f6](https://github.com/simonoscr/dotfiles/commit/94b54f6f398b7d188171d9baa889a71b43a9f4f8))



## [1.4.3](https://github.com/simonoscr/dotfiles/compare/1.4.2...1.4.3) (2024-01-20)


### Bug Fixes

* add wifi ([304ce21](https://github.com/simonoscr/dotfiles/commit/304ce214c3a7fd1a7d21834d47fc8ee84cea23ac))
* again miassing ; ([856ca61](https://github.com/simonoscr/dotfiles/commit/856ca6136b542679ca8aacf6479c0791d28a52c9))
* boolean without quotes for sure ([8a43943](https://github.com/simonoscr/dotfiles/commit/8a43943c76a25a97abb467e1f7fb49c1414d4ca1))



## [1.4.2](https://github.com/simonoscr/dotfiles/compare/1.4.1...1.4.2) (2024-01-20)


### Bug Fixes

* add keyfile path for user ([160e0b1](https://github.com/simonoscr/dotfiles/commit/160e0b140e9ecdf599281dfbc387284f6b8e0eb2))
* add owner of secrets and symlink for ssh key ([f6c16fd](https://github.com/simonoscr/dotfiles/commit/f6c16fdd0dd7db5abc6cb37ec04c14b27a4b5bd3))
* missing ; ([a844916](https://github.com/simonoscr/dotfiles/commit/a8449167418877081fe836546e3a08cbcfe61636))



## [1.4.1](https://github.com/simonoscr/dotfiles/compare/1.4.0...1.4.1) (2024-01-20)


### Bug Fixes

* add ssh key file location to openssh ([fc96b7a](https://github.com/simonoscr/dotfiles/commit/fc96b7a00a44e03934eb523c72349651aa8b4e93))
* missing ; ([d9c15b3](https://github.com/simonoscr/dotfiles/commit/d9c15b37e7f7a293814031eee7b9fec5c8222421))



# [1.4.0](https://github.com/simonoscr/dotfiles/compare/1.3.3...1.4.0) (2024-01-20)


### Bug Fixes

* import sops-nix module correct ([9dddb82](https://github.com/simonoscr/dotfiles/commit/9dddb8206d74b7a0afb636a6b809d528dff377ad))
* missing s for inputs in ssh.nix ([b59b84a](https://github.com/simonoscr/dotfiles/commit/b59b84abe472fe1d7b7108a502c1d22e2d8b3f78))
* switch linux kernel to latest instead of latest_hardened ([cf29ee5](https://github.com/simonoscr/dotfiles/commit/cf29ee5190ea5c43207243390b12a32a018d1d13))


### Features

* add ssh encryption for ssh connection - test ([417752a](https://github.com/simonoscr/dotfiles/commit/417752a8ed4312cd6d40a9f983965e26928a7e3c))



## [1.3.3](https://github.com/simonoscr/dotfiles/compare/1.3.2...1.3.3) (2024-01-19)


### Bug Fixes

* add k9s ([cde666e](https://github.com/simonoscr/dotfiles/commit/cde666edd522f0d85d05945a39bf57f3e44ffb2e))



## [1.3.2](https://github.com/simonoscr/dotfiles/compare/1.3.1...1.3.2) (2024-01-19)


### Bug Fixes

* add helm to voyager ([e4415fc](https://github.com/simonoscr/dotfiles/commit/e4415fc34b7cba6fe280d0a21a7411435e0be95e))



## [1.3.1](https://github.com/simonoscr/dotfiles/compare/1.3.0...1.3.1) (2024-01-19)


### Bug Fixes

* import missing k3s.nix ([34d4cd1](https://github.com/simonoscr/dotfiles/commit/34d4cd18b1228be93118833291d3b077afc73485))



# [1.3.0](https://github.com/simonoscr/dotfiles/compare/1.2.8...1.3.0) (2024-01-19)


### Features

* add k3s ([8ebfc2d](https://github.com/simonoscr/dotfiles/commit/8ebfc2d4de04ef3524375c411c751e66e43a40df))



## [1.2.8](https://github.com/simonoscr/dotfiles/compare/1.2.7...1.2.8) (2024-01-19)


### Bug Fixes

* add libvrtd ([20ebd1b](https://github.com/simonoscr/dotfiles/commit/20ebd1b04b9ae1617ddaac87c32b0f55b55e9f0e))



## [1.2.7](https://github.com/simonoscr/dotfiles/compare/1.2.6...1.2.7) (2024-01-19)


### Bug Fixes

* add new hardware configruation with LVM ([78d88fa](https://github.com/simonoscr/dotfiles/commit/78d88fa7a86dea86791a8b1233ea45ce5266ebd3))



## [1.2.6](https://github.com/simonoscr/dotfiles/compare/1.2.5...1.2.6) (2024-01-18)


### Bug Fixes

* vsc extensions ([4f83f24](https://github.com/simonoscr/dotfiles/commit/4f83f2436117297449a57cc469e8d81d4c07e807))



## [1.2.5](https://github.com/simonoscr/dotfiles/compare/1.2.4...1.2.5) (2024-01-18)


### Bug Fixes

* add vscodium extension ([bf0e881](https://github.com/simonoscr/dotfiles/commit/bf0e88182cc77ac61301265c198a07128cdf3b32))
* ya ([f637ca4](https://github.com/simonoscr/dotfiles/commit/f637ca4aad0c0f6c1e672aaae666db154be727bd))



## [1.2.4](https://github.com/simonoscr/dotfiles/compare/1.2.3...1.2.4) (2024-01-18)


### Bug Fixes

* modules path for host ([96530b2](https://github.com/simonoscr/dotfiles/commit/96530b23c9120acfe68871fc4f17256a18b12caa))



## [1.2.3](https://github.com/simonoscr/dotfiles/compare/1.2.2...1.2.3) (2024-01-18)


### Bug Fixes

* home name ([fff59ed](https://github.com/simonoscr/dotfiles/commit/fff59ed72d9b6ef6fecce66d73d814bd9fa22f16))



## [1.2.2](https://github.com/simonoscr/dotfiles/compare/1.2.1...1.2.2) (2024-01-18)


### Bug Fixes

* change user name ([5f46064](https://github.com/simonoscr/dotfiles/commit/5f46064159ab576d3ea17662f7f034d819c9f30c))



## [1.2.1](https://github.com/simonoscr/dotfiles/compare/1.2.0...1.2.1) (2024-01-18)


### Bug Fixes

* activate voyager host ([799e566](https://github.com/simonoscr/dotfiles/commit/799e566477ab0669981a82c7578389f0dca7f0ee))
* add hardware-configuration.nix for voyager ([3cbac0f](https://github.com/simonoscr/dotfiles/commit/3cbac0f1890d1501ecfefa6f40498fb71fb9884a))
* remove wrong/unused imports for voyager ([717973f](https://github.com/simonoscr/dotfiles/commit/717973f905b86b0cae9ed59674efa7e4537b8bd1))



# [1.2.0](https://github.com/simonoscr/dotfiles/compare/1.1.2...1.2.0) (2024-01-18)


### Features

* add home-server voyager configuration ([7133d63](https://github.com/simonoscr/dotfiles/commit/7133d63efcac6d3260d592cc5d1fc6432a011ac5))



## [1.1.2](https://github.com/simonoscr/dotfiles/compare/1.1.1...1.1.2) (2024-01-14)


### Bug Fixes

* wlroots dependency error for gamescope; wlroots version too high for gamescope ([70742a6](https://github.com/simonoscr/dotfiles/commit/70742a6546e6204bb27f4e606025adbd6cc4166b))



## [1.1.1](https://github.com/simonoscr/dotfiles/compare/1.1.0...1.1.1) (2024-01-07)


### Bug Fixes

* make swayidle able to shut off display in hyprland and change look of swaylock ([14efbd3](https://github.com/simonoscr/dotfiles/commit/14efbd31b0ec2cc7ea44c557af817309b94135c3))



# [1.1.0](https://github.com/simonoscr/dotfiles/compare/1.0.5...1.1.0) (2024-01-07)


### Features

* add i3 and hyprland session to tuigreet ([f80743c](https://github.com/simonoscr/dotfiles/commit/f80743cdbfb974f71495daa16729d476b20c69c6))



## [1.0.5](https://github.com/simonoscr/dotfiles/compare/1.0.4...1.0.5) (2024-01-07)


### Bug Fixes

* tuigreetd ([a0d0f53](https://github.com/simonoscr/dotfiles/commit/a0d0f53ec84b51be95d60b8db40616a2fc784c3c))



## [1.0.4](https://github.com/simonoscr/dotfiles/compare/1.0.3...1.0.4) (2024-01-07)


### Bug Fixes

* updated i3 configuration ([dc90015](https://github.com/simonoscr/dotfiles/commit/dc900156eabe4f45797cfbb1cd7ec445b674ba58))



## [1.0.3](https://github.com/simonoscr/dotfiles/compare/1.0.2...1.0.3) (2024-01-05)


### Bug Fixes

* update ags fixes ([ca26347](https://github.com/simonoscr/dotfiles/commit/ca263475add4f71b6eaf025e192ec1786c6c7d82))



## [1.0.2](https://github.com/simonoscr/dotfiles/compare/1.0.1...1.0.2) (2024-01-05)


### Bug Fixes

* update ags files ([df9292f](https://github.com/simonoscr/dotfiles/commit/df9292f0dd08bbcadd81f06916ba8a2e896fcf41))
* update ags fils ([f19edfb](https://github.com/simonoscr/dotfiles/commit/f19edfb4d116fd31d553cbce243a816bedce355f))



## [1.0.1](https://github.com/simonoscr/dotfiles/compare/1.0.0...1.0.1) (2024-01-04)


### Bug Fixes

* update ags ([bd2ce8f](https://github.com/simonoscr/dotfiles/commit/bd2ce8fdcd98fd301fac6b6fa0bde18a3cdba9aa))
* update ags ([6f92c46](https://github.com/simonoscr/dotfiles/commit/6f92c46cb1d9d308cec4429ec949aedc11cb79ab))



# [1.0.0](https://github.com/simonoscr/dotfiles/compare/0.6.7...1.0.0) (2024-01-03)


### Features

* change hardware ([cf2bb6f](https://github.com/simonoscr/dotfiles/commit/cf2bb6f34e826f9e4850ba1781d158697ece97ea))


### BREAKING CHANGES

* hardware configuration not for old intel set-up. It is for the AMD GPU now



## [0.6.7](https://github.com/simonoscr/dotfiles/compare/0.6.6...0.6.7) (2023-12-30)


### Bug Fixes

* add wine and bottles ([7083d44](https://github.com/simonoscr/dotfiles/commit/7083d4448c789c657d2c36923ae05d16f5e75578))



## [0.6.6](https://github.com/simonoscr/dotfiles/compare/0.6.5...0.6.6) (2023-12-29)


### Bug Fixes

* add protonup-qt ([70bcbf8](https://github.com/simonoscr/dotfiles/commit/70bcbf8acae4d7ab9d121f5ca9068028a023a558))



## [0.6.5](https://github.com/simonoscr/dotfiles/compare/0.6.4...0.6.5) (2023-12-29)


### Bug Fixes

* hyprland steam windowrules ([7498d6c](https://github.com/simonoscr/dotfiles/commit/7498d6c4629229ad651c0f7727fdc7071a1775f2))



## [0.6.4](https://github.com/simonoscr/dotfiles/compare/0.6.3...0.6.4) (2023-12-22)


### Bug Fixes

* change vscodium shortcut; add i3 ([debeaea](https://github.com/simonoscr/dotfiles/commit/debeaeaaffe28463c2cbd5f2e3a3bcd13e372424))



## [0.6.3](https://github.com/simonoscr/dotfiles/compare/0.6.2...0.6.3) (2023-12-22)


### Bug Fixes

* disable network-wait; fine-tuning tuigreet ([5b60437](https://github.com/simonoscr/dotfiles/commit/5b60437720502b2edddb4ff855a356300ac00112))



## [0.6.2](https://github.com/simonoscr/dotfiles/compare/0.6.1...0.6.2) (2023-12-22)


### Bug Fixes

* add thunar shortcut ([c702283](https://github.com/simonoscr/dotfiles/commit/c70228333a593609775697c23ee69d4b7d55d4fc))



## [0.6.1](https://github.com/simonoscr/dotfiles/compare/0.6.0...0.6.1) (2023-12-22)


### Bug Fixes

* add thunar; enable greetd ([3560f3d](https://github.com/simonoscr/dotfiles/commit/3560f3de315ff56542a6779a505f57a42a1c2c18))



# [0.6.0](https://github.com/simonoscr/dotfiles/compare/0.5.5...0.6.0) (2023-12-22)


### Features

* removed swap fileSystem and add test fileSystem; hyprland to home-manager, wayland settings, added waybar update flock ([f113064](https://github.com/simonoscr/dotfiles/commit/f113064835fb713ed7cac9bd2314d639c4904389))



## [0.5.5](https://github.com/simonoscr/dotfiles/compare/0.5.4...0.5.5) (2023-12-22)


### Bug Fixes

* set workspaces for hyprland+ags to 0 for dynamic workspaces ([4665051](https://github.com/simonoscr/dotfiles/commit/46650518f37857934bb10c01ea3431aabdbfa2a4))



## [0.5.4](https://github.com/simonoscr/dotfiles/compare/0.5.3...0.5.4) (2023-12-22)


### Bug Fixes

* codium hyprland shotcut; add sessionVariable NIXOS_OZONE_WL=1 ([d59b129](https://github.com/simonoscr/dotfiles/commit/d59b1297af2e56dd3b6887f5dbea72d31133149b))



## [0.5.3](https://github.com/simonoscr/dotfiles/compare/0.5.2...0.5.3) (2023-12-22)


### Bug Fixes

* update hyprland and ags config ([fc17b77](https://github.com/simonoscr/dotfiles/commit/fc17b77c02ac6929f92cfa8bcdf02a278f4df7d3))



## [0.5.2](https://github.com/simonoscr/dotfiles/compare/0.5.1...0.5.2) (2023-12-21)


### Bug Fixes

* gamescope, manoghud and gaming related fixes ([2c01b55](https://github.com/simonoscr/dotfiles/commit/2c01b557c43e04d668d75e00b4edb69e75cd5634))



## [0.5.1](https://github.com/simonoscr/dotfiles/compare/0.5.0...0.5.1) (2023-12-21)


### Bug Fixes

* activate steam with dependencies ([94ec00d](https://github.com/simonoscr/dotfiles/commit/94ec00d4e0a02fb984751f97f71536f3012e8e3b))



# [0.5.0](https://github.com/simonoscr/dotfiles/compare/0.4.2...0.5.0) (2023-12-20)


### Features

* add inputs; nixos-hardware, nixpkgs-wayland and smoll fixes ([40972d4](https://github.com/simonoscr/dotfiles/commit/40972d4b06223625604585150ff05bdd8852fd31))



## [0.4.2](https://github.com/simonoscr/dotfiles/compare/0.4.1...0.4.2) (2023-12-20)


### Bug Fixes

* hyprland, hm-hyprland, steam with extraPkgs and gamescope configuration ([b37a47b](https://github.com/simonoscr/dotfiles/commit/b37a47b277d551c46f02708773b58da8fe235410))



## [0.4.1](https://github.com/simonoscr/dotfiles/compare/0.4.0...0.4.1) (2023-12-17)


### Bug Fixes

* swayidle timeouts ([d287829](https://github.com/simonoscr/dotfiles/commit/d287829a6bf78810bb11e1c129c368dff7304720))



# [0.4.0](https://github.com/simonoscr/dotfiles/compare/0.3.2...0.4.0) (2023-12-17)


### Features

* add NUR nix user repository and his overlay; firefox settings ([b9d7ca0](https://github.com/simonoscr/dotfiles/commit/b9d7ca0601a9d274de16394ab4ea230a0c1580de))



## [0.3.2](https://github.com/simonoscr/dotfiles/compare/0.3.1...0.3.2) (2023-12-17)


### Bug Fixes

* enable fstrim, remove kernelParams, add neovim as nixvim module ([d3aaf94](https://github.com/simonoscr/dotfiles/commit/d3aaf94c8c70711dbe90a33097c146cc6134f7d4))



## [0.3.1](https://github.com/simonoscr/dotfiles/compare/0.3.0...0.3.1) (2023-12-16)


### Bug Fixes

* hardware-configuration; using now the new default (modesetting) in xserver.videoDriver (other drivers unmaintained) ([f9962c9](https://github.com/simonoscr/dotfiles/commit/f9962c97cf939ca268a1c0be135759d7577c52b3))



# [0.3.0](https://github.com/simonoscr/dotfiles/compare/0.2.3...0.3.0) (2023-12-15)


### Features

* add config and dotfiles ([cbe7edc](https://github.com/simonoscr/dotfiles/commit/cbe7edcf88a3d9ee873d0826ecbae201c6a32746))



## [0.2.3](https://github.com/simonoscr/dotfiles/compare/0.2.2...0.2.3) (2023-12-15)


### Bug Fixes

* remove double vscodium pkg ([540d444](https://github.com/simonoscr/dotfiles/commit/540d4447b5bee97d45014fc98a35e9a09e31a4f3))



## [0.2.2](https://github.com/simonoscr/dotfiles/compare/0.2.1...0.2.2) (2023-12-14)


### Bug Fixes

* fonts in hyprland config ([78e2ca9](https://github.com/simonoscr/dotfiles/commit/78e2ca95f70c440e7515be6dc7bc8fe7a809bdc2))



## [0.2.1](https://github.com/simonoscr/dotfiles/compare/0.2.0...0.2.1) (2023-12-14)


### Bug Fixes

* cursor theme and font settings ([c612906](https://github.com/simonoscr/dotfiles/commit/c6129061f6bb4c97b24cf9ae2c0842c9748e93ac))



# [0.2.0](https://github.com/simonoscr/dotfiles/compare/0.1.0...0.2.0) (2023-12-14)


### Features

* move steam to systemPackages and apply gamescope fix; fix theme related things ([c35322a](https://github.com/simonoscr/dotfiles/commit/c35322abda92f3e933b1e35352f57101ab5ec927))



# [0.1.0](https://github.com/simonoscr/dotfiles/compare/e82ced4c65128b4f94382bc27b991ae001613f8e...0.1.0) (2023-12-13)


### Features

* test ([718f12c](https://github.com/simonoscr/dotfiles/commit/718f12c18253c49b60f3e4963f48708772c5f57b))
* update nixos with more modules ([e82ced4](https://github.com/simonoscr/dotfiles/commit/e82ced4c65128b4f94382bc27b991ae001613f8e))
