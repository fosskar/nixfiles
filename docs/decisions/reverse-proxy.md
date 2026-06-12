# caddy over nginx

this repo migrated all service vhosts from nginx + `security.acme` to [caddy](https://caddyserver.com).

scope: this is the general reverse proxy for services. the traefik instance on `gateway` is part of the netbird proxy stack (see [overlay-network.md](overlay-network.md)) and was not part of this decision.

## why switch

### certs folded into the proxy

before: nginx vhosts plus a separate `security.acme` setup, orchestrated per vhost. caddy does automatic https itself - one wildcard cert via dns-01 (desec plugin) covers all subdomains.

dns-01 + wildcard is core rationale, not an implementation detail: lan/vpn-only services get valid tls without being publicly reachable on port 80/443. with caddy this is one `withPlugins` line; with nginx it stays a second moving part.

### forward-auth built in

sso enforcement at the proxy uses caddy's native `forward_auth` directive. nginx equivalent is `auth_request` glue per vhost.

### one config surface

nginx could have been fixed instead - `security.acme` supports dns-01 wildcard, `auth_request` works. but the same capability is spread across nginx + acme + auth glue: three config surfaces vs one. caddy vhost definitions are also drastically shorter. same consolidation theme as the other decisions in this directory.

## technical comparison

these are properties of the software, not preferences:

| aspect            | nginx                                            | caddy                                                        |
| ----------------- | ------------------------------------------------ | ------------------------------------------------------------ |
| tls by default    | opt-in; cipher suites, protocol versions, ocsp stapling, http→https redirect all manual | automatic https: modern tls defaults, ocsp stapling, redirect out of the box |
| acme              | external (`security.acme` / certbot / lego), cert paths wired into vhosts, reload hooks | built-in client: issuance, renewal, dns-01, in-process cert rotation without reload glue |
| memory safety     | c                                                | go (memory-safe runtime)                                      |
| http/3            | available, off by default                        | built in, on by default                                       |
| config reload     | signal-based reload                              | zero-downtime apply via admin api                             |
| auth at proxy     | `auth_request` subrequest glue per vhost         | first-class `forward_auth` directive                          |
| extension model   | compile-time modules or dynamic `.so`            | compile-time go plugins (`withPlugins`), declarative in nix   |

net effect: caddy's secure state is the default state; nginx's secure state is the result of correct manual configuration in several places. fewer hand-written security-relevant lines means fewer places to get it wrong.

## accepted tradeoffs

- custom plugin build (desec dns) means hash churn: plugin/go-module updates regularly need hash bumps in the caddy module.
- smaller ecosystem than nginx: fewer battle-tested reference configs for exotic setups.

## repo wiring

- `modules/nixos/services/caddy.nix`: caddy with desec dns-01 wildcard cert and forward-auth; feature modules contribute their own vhosts.
- `modules/nixos/services/nginx.nix` / `acme.nix`: legacy, unimported.
