# openwrt

declarative openwrt config management via nix → ucode → SSH.
this sits outside the nixos machine graph: nix evaluates typed device modules into json, the deploy adds secrets and pipes a ucode program (`nix/apply.uc`) to `ucode -` on the device.

inspired by [Mic92/dotfiles/openwrt](https://github.com/Mic92/dotfiles/tree/main/openwrt).

## commands

```bash
nix run .#openwrt-deploy -- <device>            # apply config, confirm or roll back
nix run .#openwrt-deploy -- <device> --dry-run  # plan only, computed on the device
nix run .#openwrt-diff -- <device>              # same as --dry-run
nix run .#openwrt-fetch -- <device> [config...] # changes from factory defaults, as nix
nix build .#openwrt-config-<device>             # inspect generated json (no secrets)
nix build .#checks.x86_64-linux.openwrt-apply-<device>  # apply twice to an empty root
```

## devices

add a device by creating `devices/<name>/config.nix` (auto-discovered).
shared settings live in `profiles/` and are imported by device configs; `profiles/roaming.nix` holds the wifi roaming contract.

| device   | model             | role    |
| -------- | ----------------- | ------- |
| `router` | GL-iNet GL-MT6000 | router  |
| `ap`     | Zyxel NWA50AX Pro | dumb AP |

## how it works

1. `devices/<name>/config.nix` defines UCI settings as nix attrsets
2. `lib.evalModules` validates config (typed options), `nix/render.nix` turns it into json
3. deploy decrypts sops, `nix/render.jq` substitutes `@placeholders@` as data, and the result is prepended to `nix/apply.uc`
4. on the device `apply.uc` removes and installs packages, then stages UCI changes in a copy of `/etc/config` (pending luci changes in `/tmp/.uci` stay out)
5. changed configs, managed files and `/etc/shadow` are snapshotted, then written atomically
6. changed configs reload (`/etc/init.d/<config> reload`, else a `config.change` event), services listed in a changed file's `restart` restart
7. deploy reconnects over a fresh SSH connection and confirms; without a confirm the device restores the snapshot 120s after the apply

**replace semantics**: options of declared sections are synced in place; options not declared are deleted, unchanged ones are not touched, so a rerun plans `no changes`.
anonymous sections (lists) replace all anonymous sections of that type; named sections of the same type stay unless the config is in `uci.exclusive`.
undeclared sections stay untouched unless the config is in `uci.exclusive`.

**rollback** covers UCI configs, files and the root password, not packages. state lives in `/tmp/nix-uci/<uuid>/` on the device (`watchdog.sh`, `apply.log`, `snapshot/`). a deploy refuses to run while an earlier one is unconfirmed.

## device options

| option                   | type           | default  | description                                                                                        |
| ------------------------ | -------------- | -------- | -------------------------------------------------------------------------------------------------- |
| `host`                   | string         | required | device IP (SSH target)                                                                             |
| `packages`               | list of string | `[]`     | packages to install via apk                                                                        |
| `externalPackages`       | list           | `[]`     | packages to install outside official feeds                                                         |
| `removePackages`         | list of string | `[]`     | packages to remove (runs before install)                                                           |
| `disableServices`        | list of string | `[]`     | init scripts to disable and stop                                                                   |
| `authorizedKeys`         | list of string | `[]`     | SSH public keys for /etc/dropbear/authorized_keys                                                  |
| `files.<path>`           | path or attrs  | `{}`     | file to push: one of `source`, `text`, `secret` (sops key = whole content), plus `mode`, `restart` |
| `rootPasswordSecret`     | string or null | `null`   | sops key with the root password; reuses the current salt, so an unchanged password plans no change |
| `uci.settings`           | attrset        | `{}`     | UCI config (replace mode)                                                                          |
| `uci.delete`             | list of string | `[]`     | UCI sections or options to delete (stale sections replace semantics leave behind)                  |
| `uci.exclusive`          | list of string | `[]`     | configs fully owned by `uci.settings`: undeclared sections are deleted                             |
| `uci.secrets.sops.files` | list of path   | `[]`     | sops files for `@placeholder@` substitution                                                        |

`files.<path>.mode` defaults to `0600` when the content has `@placeholders@` or comes from `secret`, else `0644`.

## UCI format

```nix
uci.settings = {
  # named section
  network.lan = {
    _type = "interface";
    device = "br-lan";
    proto = "static";
    ipaddr = "192.168.10.1";
  };

  # anonymous section (list)
  firewall.zone = [
    { _type = "zone"; name = "lan"; network = [ "lan" ]; input = "ACCEPT"; }
  ];
};
```

## secrets

sops + age/yubikey. secrets file at `devices/secrets.yaml`.

```bash
# create (one-time)
sops --age <your-age-pubkey> openwrt/devices/secrets.yaml

# edit
sops openwrt/devices/secrets.yaml
```

usage in device config:

```nix
uci.secrets.sops.files = [ ../secrets.yaml ];

# in uci.settings:
key = "@wifi_password@";
```

deploy decrypts via sops and substitutes `@placeholders@` in UCI values and pushed files before connecting, so a sops failure leaves the device untouched. an unknown placeholder fails the render.
plan output redacts secret values; `openwrt-fetch` prints live values unredacted.

## dns (router)

```
clients ──:53──▶ adguard home ──127.0.0.1:5335──▶ unbound ──▶ authoritative servers
                     │                               │
                 blocklists                     local names ──▶ dnsmasq :54 (dhcp_link)
```

- **adguard home** (`:53` on all vlans, web ui `:8080`): filtering via hagezi pro++, tif medium, doh bypass list. full tif (2.2M rules) needs >=2GB ram in agh (caused the 2026-07-18 oom wedge on the 1GB gl-mt6000); keep medium.
- **unbound** (`127.0.0.1:5335`): full recursion, no third-party resolver ever sees queries. qname minimization (`query_minimize`), strict dnssec validation (`validator`, trust anchor `root.key`), and a full local root zone copy (`auth_icann` zone, refreshed ~daily). root servers are never queried live. `serve-expired` + aggressive prefetch answer from cache during wan outages. binds loopback only (`unbound_srv.conf`) so lan clients cannot bypass agh filtering.
- **dnsmasq** (`:54`, lan-facing but not client-used): dhcp, tftp/pxe, and local hostname resolution; unbound forwards local names/ptr to it via `dhcp_link`.
- **bypass prevention**: port 53 is dnat-redirected to agh on every vlan (`force dns interception` redirects), dot (853→wan) is REJECTed (`Block-DoT-Bypass`), doh resolver domains are blocked by the hagezi doh list. android "private dns" in strict hostname mode will fail. set it to automatic.

## PXE / netboot

the router runs a TFTP server (`/srv/tftp/`) and serves `netboot.xyz.efi` for PXE booting.
boot any wired machine → network boot → netboot.xyz menu → **Custom** → **NixOS Installer** (live system in RAM: install, rescue, troubleshooting). no usb stick needed.

### files

```
/srv/tftp/
  netboot.xyz.efi               # netboot.xyz bootloader (dhcp_boot target)
  custom.ipxe                   # custom menu, auto-detected by netboot.xyz (generated)
  nixos/
    bzImage                     # nix-community/nixos-images kernel (stable)
    initrd                      # nix-community/nixos-images initrd (stable)
```

### populating / updating

everything is (re)built by the deployed script: it downloads the bootloader and the
current nixos stable images and regenerates `custom.ipxe` with the matching `init=`
store path parsed from the upstream ipxe script:

```bash
ssh root@192.168.10.1 sh /usr/bin/netboot-update
```

`/srv/tftp` survives reboots (overlay) but **not sysupgrades**. rerun after every
flash. bump the release by changing `REL` in `files/netboot-update`.

### UCI config

```
dhcp.@dnsmasq[0].dhcp_boot='netboot.xyz.efi'
dhcp.@dnsmasq[0].enable_tftp='1'
dhcp.@dnsmasq[0].tftp_root='/srv/tftp'
```

## structure

```
openwrt/
  README.md
  nix/
    module-options.nix          # typed device options
    render.nix                  # device config -> json, openwrt-render
    render.jq                   # secret substitution into the json
    apply.uc                    # on-device program: plan / apply with rollback
    fetch.uc                    # on-device program for openwrt-fetch
    ucode.nix                   # ucode with the uci module, for the flake check
    scripts/
      deploy.nix                # deploy script
      fetch.nix                 # fetch script
      diff.nix                  # diff script (deploy --dry-run)
  devices/
    secrets.yaml                # shared sops secrets (age/yubikey)
    router/
      config.nix                # device config
      files/                    # extra config files pushed to device
    ap/
      config.nix
```

`modules/flake-parts/openwrt.nix` wires devices, apps, packages and checks.
