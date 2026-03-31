# gateway security architecture

hetzner cloud VPS exposed to the public internet. runs netbird server (mesh VPN),
wireguard controller, and monitoring. three defense layers protect inbound traffic.

## how a request reaches a service

```
  internet
     │
     ▼
  ┌─────────────────────────────────────────────────────┐
  │  layer 1: hetzner cloud firewall (hypervisor)       │
  │                                                     │
  │  stateless packet filter at the hypervisor level,   │
  │  before the VM even sees the packet.                │
  │                                                     │
  │  allow: TCP 22, 80, 443, 6443, 6445-6446           │
  │         UDP 3478, 51820-51821                       │
  │  drop:  everything else                             │
  └──────────────────────┬──────────────────────────────┘
                         │
                         ▼
  ┌─────────────────────────────────────────────────────┐
  │  layer 2: nftables in kernel                        │
  │                                                     │
  │  two independent chains on the input hook:          │
  │                                                     │
  │  crowdsec firewall bouncer                          │
  │  ├ nftables set of banned IPs (IPv4 + IPv6)         │
  │  ├ populated by crowdsec LAPI decisions             │
  │  ├ includes CAPI community blocklist                │
  │  └ match → drop (before any userspace)              │
  │                                                     │
  │  nixos firewall                                     │
  │  ├ default policy: drop                             │
  │  ├ explicitly opened ports only                     │
  │  └ wt0 (netbird tunnel): trusted interface          │
  └──────────────────────┬──────────────────────────────┘
                         │ TCP 80 redirects to 443
                         │ TCP 443
                         ▼
  ┌─────────────────────────────────────────────────────┐
  │  layer 3: traefik reverse proxy (:443)              │
  │                                                     │
  │  entrypoint middlewares, applied to every request:   │
  │                                                     │
  │  1. geoblock plugin                                 │
  │     └ resolves client IP → country via geojs.io     │
  │     └ whitelist mode: only DE allowed               │
  │     └ non-DE → 403                                  │
  │                                                     │
  │  2. crowdsec bouncer plugin (live mode)             │
  │     └ queries crowdsec LAPI for each new IP         │
  │     └ caches result locally (default 60s)           │
  │     └ active ban decision → 403                     │
  │                                                     │
  │  then routing by Host + Path to localhost services  │
  └─────────────────────────────────────────────────────┘
```

## crowdsec: how detection and enforcement work

crowdsec is an open-source IDS/IPS. it consists of two main parts inside the
security engine, plus external remediation components (bouncers) that enforce
decisions.

```
  ┌─────────────────── security engine ───────────────────┐
  │                                                       │
  │  log processor                                        │
  │  ├ acquires logs from journald (sshd, kernel, syslog) │
  │  ├ acquires traefik access.log (HTTP requests)        │
  │  ├ parses and enriches log lines                      │
  │  ├ matches against scenario definitions               │
  │  │  (brute-force patterns, scanning, probing, etc.)   │
  │  └ triggers alerts → sends to LAPI                    │
  │                                                       │
  │  local API (LAPI, :8085)                              │
  │  ├ receives alerts from log processor                 │
  │  ├ creates ban decisions based on profiles            │
  │  ├ exposes decisions to bouncers via HTTP API         │
  │  ├ connects to central API (CAPI) to:                │
  │  │  ├ share local attack signals with the community   │
  │  │  └ receive curated community blocklist             │
  │  └ stores state in sqlite DB (/var/lib/crowdsec/)     │
  │                                                       │
  └───────────────────────────────────────────────────────┘
            │                           │
            ▼                           ▼
  ┌───────────────────┐   ┌─────────────────────────────┐
  │ firewall bouncer  │   │ traefik bouncer plugin      │
  │                   │   │                             │
  │ polls LAPI for    │   │ runs inside traefik process │
  │ ban decisions,    │   │ live mode: queries LAPI per │
  │ maintains nftables│   │ new IP, caches result       │
  │ set of banned IPs │   │                             │
  │                   │   │ ban decision → HTTP 403     │
  │ kernel-level drop │   │ no decision → pass through  │
  │ before userspace  │   │                             │
  └───────────────────┘   └─────────────────────────────┘
```

**why two bouncers?** the firewall bouncer blocks at the kernel level — banned
IPs can't reach any service at all (SSH, traefik, wireguard, everything). the
traefik bouncer adds a second check at the application layer, specifically for
HTTP traffic. this catches bans that were just created (before the firewall
bouncer's next poll) and enables finer-grained HTTP-specific decisions.

**CAPI (central API):** every crowdsec instance shares its local attack signals
with the central API. in return, it receives a curated community blocklist of
IPs that have been flagged by many participants. this is the "crowd" in
crowdsec — attack intelligence is shared across all users.

**scenarios installed:**

| collection                              | detects                                             |
| --------------------------------------- | --------------------------------------------------- |
| `crowdsecurity/linux-lpe`               | local privilege escalation attempts                 |
| `crowdsecurity/iptables`                | patterns in firewall logs                           |
| `crowdsecurity/sshd-impossible-travel`  | SSH logins from geographically impossible locations |
| `crowdsecurity/appsec-virtual-patching` | known application vulnerabilities (virtual patch)   |
| `crowdsecurity/appsec-generic-rules`    | generic application security patterns               |
| `crowdsecurity/traefik`                 | HTTP scanning, probing, path traversal, crawlers    |

## geoblock

traefik plugin ([PascalMinder/geoblock](https://github.com/PascalMinder/geoblock)).
resolves client IP to country code via [geojs.io](https://get.geojs.io) API.
operates in whitelist mode: only DE (germany) passes. local/private IPs are
always allowed. results are cached to reduce API calls.

this is a separate layer from crowdsec — it doesn't care about behavior, just
geography. most automated scanning comes from outside DE, so this eliminates a
large volume of noise before crowdsec even sees it.

## service binding

```
  traefik (:443)
     │
     ├─ Host(nb.fosskar.eu) + /api,/oauth2,/relay,/ws-proxy
     │  └→ 127.0.0.1:8081 (netbird-server, HTTP)
     │
     ├─ Host(nb.fosskar.eu) + /signalexchange,/management
     │  └→ 127.0.0.1:8081 (netbird-server, h2c/gRPC)
     │
     ├─ Host(nb.fosskar.eu) catch-all
     │  └→ 127.0.0.1:8080 (nginx, netbird dashboard)
     │
     └─ HostSNI(*) TCP passthrough
        └→ 127.0.0.1:8443 (netbird-proxy, tunnel endpoints)
```

all backend services bind to localhost. netbird-proxy listens on `0.0.0.0:8443`
(upstream limitation) but port 8443 is not opened in any firewall — it's only
reachable via traefik's TCP passthrough on port 443.

internal-only services never exposed:

| service         | address        | purpose                    |
| --------------- | -------------- | -------------------------- |
| crowdsec LAPI   | 127.0.0.1:8085 | bouncer queries, cscli     |
| traefik metrics | 127.0.0.1:8082 | prometheus scrape endpoint |

## non-HTTP services

SSH (22), yggdrasil (6443, 6445-6446), wireguard (51820-51821), and STUN (3478)
don't go through traefik. they pass through hetzner firewall → crowdsec nftables
blacklist → nixos firewall → directly to the service. SSH is further protected by
crowdsec's sshd scenarios (brute-force, impossible travel).

## persistence

ephemeral root (btrfs, rolled back every boot). only these paths survive:

| path                      | contents                                  |
| ------------------------- | ----------------------------------------- |
| `/var/lib/crowdsec`       | engine DB, CAPI credentials, bouncer keys |
| `/var/lib/traefik`        | ACME TLS certificates                     |
| `/var/lib/netbird-server` | management DB, proxy token                |
| `/var/lib/netbird-proxy`  | proxy state, TLS certs                    |
| `/var/lib/netbird`        | netbird client identity                   |
