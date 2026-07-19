# authelia + lldap over pocket-id, kanidm, and the enterprise idps

this repo runs [authelia](https://www.authelia.com) (oidc provider + forward-auth) backed by [lldap](https://github.com/lldap/lldap) (user directory) on nixbox.

scope: the whole identity stack — oidc provider, proxy forward-auth, and user store — decided as one composition. reverse proxy choice is separate (see [reverse-proxy.md](reverse-proxy.md)).

## the core claim

authelia is the only option that satisfies both of these at once:

1. **oidc provider and forward-auth in one component.** services with real oidc support (immich, grafana, nextcloud, ...) and services with no auth at all (the arr stack, victoriametrics) are covered by the same daemon, same session, same acl rules, same group model. every alternative needs a second auth middleware (tinyauth, oauth2-proxy, caddy-security) next to the provider — component count goes up, and session/policy state splits across two systems.
2. **config-file driven, so nix-declarative.** client registrations, secret hashes, acl rules, and claims policies are rendered from nix. the `{{ secret }}` template + pbkdf2-hash design is what makes the clan vars pattern possible: a generator produces the client secret, hashes it for authelia, and hands the plaintext to the consuming service. plaintext never enters the config, both halves regenerate deterministically, and a machine rebuilds from zero with `clan vars generate` — no admin ui clicking, ever.

each alternative wins on one axis and loses the intersection.

## where declarative ends — on purpose

"fully declarative" would be an overclaim. the boundary:

- **declarative (nix, in repo):** oidc clients (~16 across the service modules), secret hashes, access control rules, authorization policies, claims policies, session/2fa config.
- **runtime state (deliberately):** users, groups, passwords, passkeys, totp secrets. lldap holds the directory, authelia's sqlite holds credentials and opaque subs. this keeps family members' personal data out of the nix store and git, and lets the household be managed through lldap's web ui instead of commits.

machine config is code; human identity is state. that split is a design choice, not a gap — it also means kanidm's headline advantage (nix-provisioned users) is a feature this repo explicitly does not want.

## alternatives

| aspect                | authelia + lldap                                    | pocket-id                                               | kanidm                            | authentik                          | keycloak             | zitadel              |
| --------------------- | --------------------------------------------------- | ------------------------------------------------------- | --------------------------------- | ---------------------------------- | -------------------- | -------------------- |
| oidc provider         | yes                                                 | yes                                                     | yes                               | yes                                | yes                  | yes                  |
| forward-auth built in | yes (caddy `forward_auth` endpoint)                 | no — docs point at tinyauth/oauth2-proxy/caddy-security | no                                | yes (embedded outpost)             | no                   | no                   |
| declarative clients   | yes (nix → yaml, secret as hash)                    | no — admin ui, secrets in its db                        | yes (`services.kanidm.provision`) | partial (blueprints applied to db) | no (db, ui/api)      | no (db, ui/api)      |
| user management       | none — needs external store (lldap)                 | built-in ui                                             | built-in + nix-provisionable      | built-in ui                        | built-in ui          | built-in ui          |
| passkeys              | yes, plus password+totp fallback                    | passkey-only (hard requirement)                         | yes — passkey-first               | yes                                | yes                  | yes                  |
| policy depth          | acl tiers, claims expressions, per-client lifespans | group-based client access                               | group/claim mapping               | full, via db objects               | full, via db objects | full, via db objects |
| weight                | 3 units (authelia, lldap, redis)                    | 1 unit                                                  | 1 unit                            | django + postgres + redis + worker | jvm + postgres       | go + postgres        |

why each loses:

- **pocket-id**: simplest runtime, but no forward-auth (would add a middleware, netting zero component savings) and clients are hand-clicked in the ui with secrets shown once — the clan vars pattern dies, rebuild-from-zero starts depending on db backups. passkey-only also removes the password+totp fallback the household relies on.
- **kanidm**: the strongest declarative rival — clients, users, and groups all provisionable from nix. but no forward-auth, no claims expressions or per-client token lifespans, and its declarative-users advantage is exactly the "identity in git" property this repo rejects.
- **authentik / keycloak / zitadel**: enterprise-shaped. multi-tenancy, scim, admin delegation — problems this network does not have, paid for with heavy runtimes and client state living in a database managed through a ui or api. worse on both axes at once.

## in-use features that would not survive a switch

these are load-bearing, not decoration:

- forward-auth over the arr stack, sabnzbd, victoriametrics via the shared caddy `(authelia)` snippet
- acl tiering: default `two_factor`, `group:user` → `one_factor` on `*.nx3.eu`
- claims policies putting `groups` into `id_token` (grafana, garage-ui, traccar, opencloud role mapping)
- custom claim expression for the immich role (`"admin" in groups ? "admin" : "user"`)
- per-client refresh-token lifespan (opencloud, 1y)

## accepted tradeoffs

- **sso is a single point of failure on nixbox.** authelia, lldap, and redis run on one host with no ha story. nixbox down means login is down for every service on every machine, including everything behind forward-auth. accepted: the same host already carries most of the services being protected.

## re-evaluate when

- kanidm (or pocket-id) grows a native forward-auth endpoint, or
- the repo's stance on identity-in-git flips (then kanidm's provisioning wins the declarative axis outright).

## repo wiring

- `modules/nixos/services/authelia.nix`: authelia instance, secrets generator, acl, session, 2fa
- `modules/nixos/services/lldap.nix`: directory, backup state, homepage tile
- `modules/nixos/services/caddy/caddy.nix`: `(authelia)` forward-auth snippet imported per vhost
- per-service oidc clients: each feature module registers its own client + secret generator (feature-owned integration)
