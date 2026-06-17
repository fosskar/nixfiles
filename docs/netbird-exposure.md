# netbird public exposure

Public `*.fosskar.eu` ingress is the **netbird-proxy** on `gateway`, fronted by
traefik TCP passthrough (`HostSNI(*)`). The mapping from a public domain to an
internal service is configured **in the netbird mgmt UI**, not in this repo. The
repo only owns the service's socket binding and firewall posture; the mgmt store
is authoritative for what is exposed where.

## model

A netbird **service** (a public `domain`) maps to one or more **targets**. A
target is `{ target_type, target_id, protocol, port }` where `target_type` is
`peer` (an internal machine), `host`, or `domain`. Internal services map
straight to the peer's app port — there is **no caddy hop** on internal peers
(radicle, nixbot, etc. all go domain -> peer:appPort directly).

Two distinct exposure mechanisms exist; do not conflate them:

- **UI service with a `peer` target** (the mechanism in use here): traffic is
  routed over the mesh to the **peer's wt0 IP**:port. The service therefore MUST
  bind a mesh-reachable address (`0.0.0.0:<port>` or the wt0 IP). `127.0.0.1` is
  invisible to the proxy.
- **`netbird expose` CLI** (not used here): creates a peer-local tunnel that can
  forward to `127.0.0.1`. Different path, different binding rules.

## rules for an exposed service module

- bind `0.0.0.0:<port>` (or the wt0 IP), never `127.0.0.1`.
- keep the LAN closed: `openFirewall = false` (or otherwise do not open the port
  on the LAN interface). wt0 is a trusted interface, so the port is reachable
  over the mesh only.
- the public DNS name and the UI service/target are created out-of-band; the
  module change alone does not expose anything.

## inspect live mappings (read-only, on gateway)

The mgmt store is sqlite at `/var/lib/netbird-server/store.db`. Inspect without
mutating:

```bash
ssh gateway.s 'nix shell nixpkgs#sqlite -c sqlite3 /var/lib/netbird-server/store.db \
  "select s.name, s.mode, s.listen_port, t.protocol, t.port, t.target_type, t.target_id \
   from services s left join targets t on t.service_id = s.id order by s.name;"'
```

Peer id <-> name/ip:

```bash
ssh gateway.s 'nix shell nixpkgs#sqlite -c sqlite3 /var/lib/netbird-server/store.db \
  "select id, name, ip from peers;"'
```

Relevant tables: `services`, `targets`, `peers`, `proxies`, `domains`. The
`netbird-server` binary CLI only manages proxy tokens, not service listings;
read the store directly for discovery.
