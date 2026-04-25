# openwrt

declarative openwrt config management via nix → UCI → SSH.
this sits outside the nixos machine graph: nix evaluates typed device modules, renders UCI batch commands, then deploys them over SSH.

inspired by [Mic92/dotfiles/openwrt](https://github.com/Mic92/dotfiles/tree/main/openwrt).

## commands

```bash
nix run .#openwrt-deploy -- <device>            # apply config
nix run .#openwrt-deploy -- <device> --dry-run  # preview only
nix run .#openwrt-fetch -- <device>             # dump current UCI config
nix run .#openwrt-diff -- <device>              # diff against factory defaults
nix build .#openwrt-uci-<device>                # inspect generated batch file
```

## devices

add a device by creating `devices/<name>/config.nix` — auto-discovered.

| device   | model             | role    |
| -------- | ----------------- | ------- |
| `router` | GL-iNet GL-MT6000 | router  |
| `ap`     | Zyxel NWA50AX Pro | dumb AP |

## how it works

1. `devices/<name>/config.nix` defines UCI settings as nix attrsets
2. `lib.evalModules` validates config (typed options)
3. pure nix serializer converts attrsets → UCI batch commands
4. deploy: `uci batch` (stage) → `uci commit` (persist) → service reload
5. only changed configs are committed and reloaded (idempotent)

**replace semantics**: declared sections are fully replaced. undeclared sections stay untouched.
options not declared within a section fall back to openwrt built-in defaults.

## device options

| option                   | type           | default  | description                                              |
| ------------------------ | -------------- | -------- | -------------------------------------------------------- |
| `host`                   | string         | required | device IP (SSH target)                                   |
| `packages`               | list of string | `[]`     | packages to install via apk                              |
| `removePackages`         | list of string | `[]`     | packages to remove (runs before install)                 |
| `authorizedKeys`         | list of string | `[]`     | SSH public keys for /etc/dropbear                        |
| `files`                  | attrsOf path   | `{}`     | files to push (key = remote path, val = local)           |
| `reload`                 | list of string | `[]`     | extra services to reload (auto-derived from UCI configs) |
| `uci.settings`           | attrset        | `{}`     | UCI config (replace mode)                                |
| `uci.secrets.sops.files` | list of path   | `[]`     | sops files for `@placeholder@` substitution              |

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

deploy decrypts via sops, substitutes `@placeholders@`, pipes to device via SSH.
fails if unsubstituted placeholders remain.

## PXE / netboot

the router runs a TFTP server (`/srv/tftp/`) and serves `netboot.xyz.efi` for PXE booting.

### files

```
/srv/tftp/
  netboot.xyz.efi               # netboot.xyz bootloader (dhcp_boot target)
  custom.ipxe                   # custom menu, auto-detected by netboot.xyz
  nixos/
    bzImage                     # nix-community/nixos-images kernel
    initrd                      # nix-community/nixos-images initrd
    boot.ipxe                   # standalone boot script (optional)
```

### usage

PXE boot any machine → netboot.xyz menu → **Custom** → **NixOS Installer**

### updating images

```bash
ssh root@192.168.10.1
cd /srv/tftp/nixos
wget -O bzImage 'https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/bzImage-x86_64-linux'
wget -O initrd 'https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/initrd-x86_64-linux'
```

after updating, check the [ipxe script](https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/netboot-x86_64-linux.ipxe) for updated `init=` path and update `custom.ipxe` accordingly.

### UCI config

```
dhcp.@dnsmasq[0].dhcp_boot='netboot.xyz.efi'
dhcp.@dnsmasq[0].enable_tftp='1'
dhcp.@dnsmasq[0].tftp_root='/srv/tftp'
```

## structure

```
openwrt/
  flake-module.nix              # flake-parts entry point
  README.md
  nix/
    lib.nix                     # UCI serializer
    module-options.nix          # typed device options
    uci.nix                     # UCI batch + sops handling
    scripts/
      deploy.nix                # deploy script
      fetch.nix                 # fetch script
      diff.nix                  # diff script
  devices/
    secrets.yaml                # shared sops secrets (age/yubikey)
    router/
      config.nix                # device config
      files/                    # extra config files pushed to device
    ap/
      config.nix
```
