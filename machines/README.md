# machines

all machines use [preservation](../docs/decisions/state-persistence.md) (ephemeral root, opt-in state persistence).

## configuration model

machine configs are composition edges: feature/aspect modules are exposed through `flake.modules.*` and assembled per host through imports and clan inventory.

### bootstrap caveat

first install of a new machine **must** be done with preservation **disabled** (do not import the module yet).
rollback wipes root on every boot, but secrets (sops) are written to root during install — so they get wiped before any service runs.

two-step bootstrap:

1. install without preservation → machine boots, secrets land on root, services start
2. import preservation + `clan machines update` → preservation activates, secrets copied to `/persist`, rollback works from boot 2+

---

## networking

### IP allocation scheme

| range       | purpose                                          |
| ----------- | ------------------------------------------------ |
| `.1-.99`    | network infra (router, APs, switches, KVMs)      |
| `.100-.199` | personal devices (workstations, laptops, phones) |
| `.200-.255` | servers                                          |

### static IPs

source of truth: `flake.hosts` in `modules/flake-parts/hosts.nix` — machine
`networking.nix`, the `internet`/`wireguard` inventory instances, and feature
modules all read from it. this table is a derived copy; update `hosts.nix` first.

| machine       | IP               | method                               |
| ------------- | ---------------- | ------------------------------------ |
| simon-desktop | `192.168.10.100` | NixOS static, no DHCP                |
| lpt-titan     | `192.168.10.150` | NixOS static + DHCP (roaming laptop) |
| nixbox        | `192.168.20.200` | NixOS static, no DHCP                |
| nixworker     | `192.168.20.210` | NixOS static, no DHCP                |
| gateway       | `138.201.155.21` | hetzner                              |

servers define their own static IP in `networking.nix` with `useDHCP = false` per interface.
the laptop keeps DHCP enabled so it works on other networks.

---

## simon-desktop

daily driver workstation (ryzen 7 7800x3d, rx 7800xt, 32gb ddr5)

**desktop:**

- niri wayland compositor
- low latency pipewire audio
- yubikey u2f auth

**dev/gaming:**

- docker + podman
- steam, gamemode, gamescope

**hardware:**

- amd gpu (lact for fan control, opencl, vulkan)
- amd cpu (zenpower, zenstates)
- tailscale mesh vpn

---

## lpt-titan

framework 13 laptop (ryzen ai 5 340, radeon 840m, 32gb ddr5)

**desktop:**

- niri wayland compositor
- low latency pipewire audio
- fingerprint auth (fprintd)
- yubikey u2f auth

**hardware:**

- nixos-hardware framework-amd-ai-300-series
- bcachefs root filesystem
- secure boot via lanzaboote
- amd igpu (no lact/opencl needed)
- tuned with power-profiles-daemon integration
- tailscale mesh vpn

---

## nixbox

home server at `192.168.20.200` (ryzen 7 5700x, 64gb, nvidia rtx pro 4000, zfs)

### infrastructure

| service    | port   | domain    | notes                     |
| ---------- | ------ | --------- | ------------------------- |
| caddy      | 80/443 | \*.nx3.eu | reverse proxy, acme certs |
| postgresql | 5432   | -         | database backend          |

**storage:**

- zfs pool `tank` with datasets: apps, media, shares, backup (legacy mountpoints, mounted via `fileSystems`)
- media dirs: `/tank/media/{books,movies,music,podcasts,tv}`
- user shares: `/tank/shares/{simon,ina,shared}`

**ups:** eaton ellipse pro via nut (usbhid-ups)

### auth

| service  | port  | domain          | notes                  |
| -------- | ----- | --------------- | ---------------------- |
| lldap    | 17170 | ldap.nx3.eu     | ldap directory         |
| authelia | 9091  | auth.fosskar.eu | sso/2fa, oidc provider |

### monitoring

| service         | port       | domain         | notes                             |
| --------------- | ---------- | -------------- | --------------------------------- |
| beszel          | 8090/18876 | beszel.nx3.eu  | lightweight monitoring            |
| victoriametrics | -          | vm.nx3.eu      | tsdb, scrapes openwrt nodes       |
| grafana         | -          | grafana.nx3.eu | dashboards                        |
| telegraf        | -          | -              | system, zfs, upsd, sensors, smart |
| victorialogs    | -          | -              | log database                      |

### media

| service   | port | domain           | notes              |
| --------- | ---- | ---------------- | ------------------ |
| jellyfin  | 8096 | jellyfin.nx3.eu  | media server       |
| seerr     | 5055 | seerr.nx3.eu     | request management |
| immich    | 2283 | immich.nx3.eu    | photo management   |
| navidrome | 4533 | navidrome.nx3.eu | music streaming    |

### arr stack

| service   | port | domain          | notes                      |
| --------- | ---- | --------------- | -------------------------- |
| prowlarr  | 9696 | prowlarr.nx3.eu | indexer manager            |
| sonarr    | 8989 | sonarr.nx3.eu   | tv shows                   |
| radarr    | 7878 | radarr.nx3.eu   | movies                     |
| lidarr    | 8686 | lidarr.nx3.eu   | music                      |
| bazarr    | 6767 | -               | subtitles                  |
| sabnzbd   | 8080 | sabnzbd.nx3.eu  | usenet client              |
| recyclarr | -    | -               | trash guides sync (weekly) |

all services run as `media` group with umask 0027

### documents & security

| service     | port | domain       | notes                         |
| ----------- | ---- | ------------ | ----------------------------- |
| vaultwarden | 8222 | vault.nx3.eu | password manager (postgresql) |

### ai/llm

| service   | port  | notes                       |
| --------- | ----- | --------------------------- |
| llama-cpp | 18080 | cuda on nvidia rtx pro 4000 |

### networking

| service  | port | domain          | notes                              |
| -------- | ---- | --------------- | ---------------------------------- |
| netbird  | -    | -               | mesh vpn client and routing server |
| homepage | -    | home.nx3.eu     | dashboard                          |
| opensoho | 8091 | opensoho.nx3.eu | openwrt device controller          |

### backup

borgbackup with zfs snapshots:

- `/persist` - system state
- `/tank/apps` - application data
- `/tank/shares` - user files

---

## nixworker

minisforum ms-a2 at `192.168.20.210` (ryzen 9 9955hx 16c/32t, 96gb ddr5)

### ci/cd

| service | port | domain            | notes                 |
| ------- | ---- | ----------------- | --------------------- |
| nixbot  | 8010 | nixbot.fosskar.eu | ci via nixbot, github |

nixbot evaluates `.#checks` on push/PR: all nixos machines, packages, devshells.
scheduled nixbot effects create per-input flake update PRs nightly.

### nix infrastructure

| service  | port | notes                                    |
| -------- | ---- | ---------------------------------------- |
| harmonia | 5000 | binary cache serving local nix store     |
| ncps     | 8501 | proxy upstream caches (nixos, community) |

other machines offload builds here via `nix.buildMachines` (remote builder).

### dev

- zed remote server via ssh (96gb ram for big evals, test vms)
- `nix-ld` enabled for dynamic linker compat

---

## gateway

hetzner vps cx22 - reverse proxy and vpn edge

### services

| service   | domain                     | notes                                      |
| --------- | -------------------------- | ------------------------------------------ |
| netbird   | nb.fosskar.eu              | management, signal, relay, dashboard       |
| traefik   | fosskar.eu / \*.fosskar.eu | tls ingress and netbird proxy routing      |
| crowdsec  | -                          | intrusion detection, nftables bouncer      |
| wireguard | -                          | clan wireguard controller and peer gateway |

**edge config:**

- public service domain: nb.fosskar.eu
- netbird proxy base domain: fosskar.eu
- geoblock middleware on traefik
- crowdsec integration with traefik and netbird-proxy bouncers

**crowdsec collections:**

- linux-lpe, traefik, iptables
- sshd-impossible-travel
- appsec-virtual-patching, appsec-generic-rules

**traefik entrypoints:**

- tcp-8428: victoriametrics remote write
- tcp-9428: victorialogs

**hardware:** srvos hetzner-cloud preset, tuned virtual-guest + network-latency
