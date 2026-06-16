# Topology

Network/service topology of the clan, rendered by
[nix-topology](https://github.com/oddlama/nix-topology).

- Per-host nodes (interfaces, services, IPs) are **derived** from each machine's
  NixOS config — `topology.self` in `machines/<host>/networking.nix`, with host
  IPs read from the static `networking.*` config where one exists.
- The shared graph (OpenWrt router, dumb AP, the internet, and the
  home/server/IoT networks) is declared centrally in
  `modules/flake-parts/topology.nix` (sourced from `openwrt/devices/*/config.nix`).
- The NixOS extractor is wired onto every host via
  `modules/nixos/common/base/topology.nix`.

## Main view

![main topology](./docs/topology/main.svg)

## Network-centric view

![network topology](./docs/topology/network.svg)

## Hosts

| Host          | Interface | Address        | Network  | Icon         | Info                  |
| ------------- | --------- | -------------- | -------- | ------------ | --------------------- |
| gateway       | wan       | 138.201.155.21 | internet | cloud-server | hetzner vps           |
| nixbox        | bond0     | 192.168.20.200 | server   | nixos        | server / 10gbe bond   |
| nixworker     | bond0     | 192.168.20.210 | server   | nixos        | server / remote build |
| simon-desktop | lan       | 192.168.10.100 | home     | desktop      | workstation           |
| lpt-titan     | wlan      | 192.168.10.150 | home     | laptop       | laptop (wifi via AP)  |

## Networks

| Network  | Name        | CIDR            |
| -------- | ----------- | --------------- |
| home     | Home LAN    | 192.168.10.0/24 |
| server   | Server LAN  | 192.168.20.0/24 |
| iot      | IoT Network | 192.168.50.0/24 |
| internet | Internet    | —               |

## Infrastructure (non-NixOS, hand-declared)

| Node   | Device               | Addresses                                                           |
| ------ | -------------------- | ------------------------------------------------------------------- |
| router | OpenWrt Router       | br-lan 192.168.10.1 / br-servers 192.168.20.1 / br-iot 192.168.50.1 |
| ap     | Zyxel NWA50AX (dumb) | 192.168.10.2 (wifi bridged onto br-lan)                             |

## Regenerate

```sh
out=$(nix build .#topology.x86_64-linux.config.output --no-link --print-out-paths)
install -m644 "$out"/main.svg    docs/topology/main.svg
install -m644 "$out"/network.svg docs/topology/network.svg
```
