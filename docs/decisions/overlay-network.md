# netbird over tailscale and pangolin

this repo migrated from running [tailscale](https://tailscale.com) (mesh vpn) plus [pangolin](https://github.com/fosrl/pangolin) (public service exposure) to a single self-hosted [netbird](https://netbird.io) deployment.

## what the overlay network is for

one network, several roles:

- clan overlay network: all clan machines peer with each other across lan and the hetzner vps gateway
- remote access: laptop/phone reach home services from anywhere
- public access: internal services exposed to the internet through the netbird reverse proxy on the gateway
- plain vpn: route traffic through peers (`routingFeatures = "client"/"server"`)

## why switch

### one tool instead of two

tailscale and pangolin each covered half the problem:

| role                    | before    | after                            |
| ----------------------- | --------- | -------------------------------- |
| mesh vpn between peers  | tailscale | netbird mesh                     |
| public service exposure | pangolin  | netbird reverse proxy on gateway |

netbird covers both, so the second tool became redundant. fewer moving parts: one control plane, one client, one set of secrets, one clan service.

### fully open source, fully self-hosted

- tailscale's control plane is closed SaaS. headscale exists, but it is a third-party reimplementation, not vendor-supported, and lags behind on features - and even with headscale a second tool for public exposure would still be needed.
- netbird's entire stack is open source and vendor-supported for self-hosting: management, signal, relay, dashboard, and embedded IdP all run on the gateway, wired through the `netbird` clan service (`clan-services/netbird/`).
- pangolin is open source and self-hosted too, but it is exposure-only (tunnel + reverse proxy via newt clients), not a mesh - it could never replace tailscale, only complement it.

### peer-to-peer

wireguard mesh with direct peer connections where possible, relay fallback otherwise. not unique to netbird (tailscale does this too), but table stakes the replacement had to keep.

## technical comparison

| aspect             | tailscale                                   | pangolin                                            | netbird                                     |
| ------------------ | ------------------------------------------- | --------------------------------------------------- | ------------------------------------------- |
| data plane         | wireguard (userspace wireguard-go only)     | wireguard tunnels to central node (newt)            | wireguard, kernel module when available     |
| topology           | p2p mesh, derp relay fallback               | hub-and-spoke: all traffic hairpins through the vps | p2p mesh, turn relay fallback               |
| lan-to-lan traffic | direct                                      | via vps even between lan peers                      | direct                                      |
| control plane      | closed SaaS (headscale: third-party reimpl) | self-hosted                                         | self-hosted, vendor-supported               |
| service exposure   | none first-party (funnel is SaaS-bound)     | core feature (reverse proxy)                        | reverse proxy on gateway + `netbird expose` |
| auth               | SaaS identity providers                     | own users or oidc                                   | embedded IdP or external oidc               |

kernel wireguard and direct p2p paths are measurable differences, not taste: lan peers exchange traffic at line rate without a vps round-trip, and the data plane avoids the userspace packet-copy overhead tailscale always has.

## accepted tradeoffs

- reverse proxy has two modes with bind-address pitfalls: permanent dashboard/api peer targets need the service reachable on the peer's netbird interface (bind `0.0.0.0` or the netbird ip); `netbird expose` creates ephemeral tunnels for `127.0.0.1` services.
- services bound to `127.0.0.1` on a peer are not reachable over the mesh. tailscale's `tailscaled` has the same model; this is inherent to interface-based overlays, not netbird-specific.
- control plane state (peers, acls, setup keys) is managed in the dashboard, not fully declaratively. tailscale and pangolin shared this problem, so nothing was lost - but nothing was gained either.

## repo wiring

- `clan-services/netbird/`: clan service with `server` and `client` roles; server runs the full stack on `gateway`, clients are joined via a shared setup key (clan vars).
- `modules/nixos/services/netbird/`: custom module set (server stack, client, reverse proxy).
- see `clan-services/netbird/README.md` for settings and usage.
