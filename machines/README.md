# machines

all machines use [preservation](../docs/preservation.md) (ephemeral root, opt-in state persistence).

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

## hm-nixbox

home server at `192.168.10.80` (ryzen 7 5700x, 64gb, intel arc b580, zfs)

### infrastructure

| service    | port   | domain       | notes                           |
| ---------- | ------ | ------------ | ------------------------------- |
| nginx      | 80/443 | \*.osscar.me | reverse proxy, acme certs       |
| postgresql | 5432   | -            | database backend                |
| samba      | 445    | -            | smb3 encrypted, per-user shares |
| avahi      | -      | -            | mdns/bonjour for mac/ios        |

**storage:**

- zfs pool `tank` with datasets: apps, media, shares, backup
- media dirs: `/tank/media/{books,movies,music,podcasts,tv}`
- user shares: `/tank/shares/{simon,ina,shared}`
- samba: smb3_11 minimum, encryption required, recycle bin

**ups:** eaton ellipse pro via nut (usbhid-ups)

### auth

| service  | port  | domain          | notes                  |
| -------- | ----- | --------------- | ---------------------- |
| lldap    | 17170 | ldap.osscar.me  | ldap directory         |
| authelia | 9091  | auth.fosskar.eu | sso/2fa, oidc provider |

### monitoring

| service         | port       | domain            | notes                             |
| --------------- | ---------- | ----------------- | --------------------------------- |
| beszel          | 8090/45876 | beszel.osscar.me  | lightweight monitoring            |
| victoriametrics | -          | vm.osscar.me      | tsdb, scrapes openwrt nodes       |
| grafana         | -          | grafana.osscar.me | dashboards                        |
| telegraf        | -          | -                 | system, zfs, upsd, sensors, smart |
| glances         | 61208      | -                 | real-time system stats            |

### media

| service        | port  | domain                   | notes                             |
| -------------- | ----- | ------------------------ | --------------------------------- |
| jellyfin       | 8096  | jellyfin.osscar.me       | media server, intel qsv transcode |
| jellyseerr     | 5055  | jellyseerr.osscar.me     | request management                |
| immich         | 2283  | immich.osscar.me         | photo management                  |
| audiobookshelf | 13378 | audiobookshelf.osscar.me | audiobooks/podcasts               |

### arr stack

| service   | port | domain             | notes                      |
| --------- | ---- | ------------------ | -------------------------- |
| prowlarr  | 9696 | prowlarr.osscar.me | indexer manager            |
| sonarr    | 8989 | sonarr.osscar.me   | tv shows                   |
| radarr    | 7878 | radarr.osscar.me   | movies                     |
| lidarr    | 8686 | lidarr.osscar.me   | music                      |
| readarr   | 8787 | readarr.osscar.me  | books                      |
| bazarr    | 6767 | -                  | subtitles                  |
| sabnzbd   | 8080 | sabnzbd.osscar.me  | usenet client              |
| recyclarr | -    | -                  | trash guides sync (weekly) |

all services run as `media` group with umask 0027

### documents & security

| service     | port  | domain          | notes                         |
| ----------- | ----- | --------------- | ----------------------------- |
| paperless   | 28981 | docs.osscar.me  | document management           |
| vaultwarden | 8222  | vault.osscar.me | password manager (postgresql) |

### ai/llm

| service | port  | notes                    |
| ------- | ----- | ------------------------ |
| ollama  | 11434 | vulkan on intel arc b580 |

**models:** deepseek-r1:7b, qwen3:8b, gemma3:4b, minicpm-v:8b (vision)

### networking

| service  | notes                               |
| -------- | ----------------------------------- |
| newt     | pangolin tunnel client to hzc-pango |
| homepage | dashboard at home.osscar.me         |

### backup

borgbackup with zfs snapshots:

- `/persist` - system state
- `/tank/apps` - application data
- `/tank/shares` - user files

---

## hzc-pango

hetzner vps cx22 - reverse proxy and tunnel server

### services

| service  | domain              | notes                                 |
| -------- | ------------------- | ------------------------------------- |
| pangolin | pangolin.fosskar.eu | tunnel server, traefik ingress        |
| crowdsec | -                   | intrusion detection, nftables bouncer |

**pangolin config:**

- base domain: fosskar.eu
- geoblock (blacklist): RU, CN, HK, IR, KP, BY, BR, US, VN, IN, ID, PK
- maxmind geoip enabled
- crowdsec integration with traefik bouncer

**crowdsec collections:**

- linux-lpe, traefik, iptables
- sshd-impossible-travel
- appsec-virtual-patching, appsec-generic-rules

**traefik entrypoints:**

- tcp-8428: victoriametrics remote write
- tcp-9428: victorialogs

**hardware:** srvos hetzner-cloud preset, tuned virtual-guest + network-latency
