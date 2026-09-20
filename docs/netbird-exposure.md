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
  on the LAN interface).
- do not open the port for wt0 in the NixOS firewall; it has no effect (see
  below).
- the public DNS name and the UI service/target are created out-of-band; the
  module change alone does not expose anything.

## the NixOS firewall does not apply to wt0

The netbird client inserts `iifname "wt0" accept` as the first rule of every
foreign `input` filter chain (`nixos-fw input`, `yggdrasil-filter input`) and
re-inserts it through a netlink monitor whenever the ruleset changes
(`client/firewall/nftables/chains_linux.go`, `acceptExternalChainsRules`).
`trustedInterfaces`, `allowedTCPPorts`, and `openFirewall` are therefore never
evaluated for mesh traffic. This cannot be turned off.

Mesh traffic is filtered by netbird's own `table ip netbird` /
`netbird-acl-input-rules` chain, which ends in `drop`. The mgmt server
generates one `proxy peer -> peer:port` rule per UI service target, plus the
group policies. Creating a service target in the UI is what opens the port;
nothing on the host has to change. Inspect the live rules read-only with
`nft list ruleset | sed -n '/chain netbird-acl-input-rules/,/^\t}/p'`.

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

## access control (mgmt state, not in this repo)

Account settings, groups and policies live in the mgmt store and are set
through the UI or `PUT /api/accounts/{id}`; the server config file has no
knob for them. Current model, set 2026-09:

- `jwt_groups_enabled: true`, `jwt_groups_claim_name: "groups"`,
  `jwt_allow_groups: []` (no NetBird-side filter). Authelia emits the
  `groups` claim for the `netbird` client
  (`modules/nixos/services/netbird/authelia.nix`) and its
  `authorization_policy = "users"` only lets the Authelia groups `user` and
  `admin` complete the login, so those become NetBird groups of the same
  name and the user's auto-groups; `groups_propagation_enabled` applies them
  to all peers that user logs in with.
- the `Default` (`All -> All`) policy is disabled.
- `admin -> All`: everything. In practice the admin's devices sit in
  `remote`, so `remote -> server`, `remote -> workstation` and the
  `remote -> home-*` rules are what carries admin access.
- `user -> home-caddy` (tcp 80/443), `user -> home-router` (dns 53),
  `user -> exit-home`: `*.nx3.eu`, name resolution and the exit node, each
  with the `at home` posture check. Nothing else.
- setup-key peers have no user and stay group-managed: `server` (all
  machines incl. `gateway`; destination of `workstation -> server` and
  `remote -> server`), `home-server` (`nixbox`, `nixworker`; the only
  bidirectional all-port policy, `home-server <-> home-server`),
  `workstation`, `remote` (roaming admin devices, e.g. `lpt-titan`).
  `gateway` is the public edge and is deliberately not in `home-server`: it
  gets no inbound `wt0` access to the home machines. The proxy runs as its
  own ephemeral peer with per-target port rules generated by the mgmt server.
- the `clan-vars` setup key has no auto-groups: a freshly enrolled machine
  can reach nothing until it is put into a group in the UI.
- `home-dns` nameserver group is served to `remote`, `admin`, `user`.

Onboarding a new person: add them to the Authelia `user` group and approve
the user in the mgmt UI (`user_approval_required`). No NetBird-side group
work. Onboarding a new machine: enroll with the `clan-vars` key, then add
the peer to `server`/`home-server` or `workstation` in the UI.
