## Usage

```nix
inventory.instances = {
  netbird = {
    module = {
      name = "netbird";
      input = "self";
    };
    roles.server.machines."gateway".settings = {
      domain = "nb.example.com";
      proxyDomain = "proxy.example.com";
      port = 51821;
      proxyTCPPorts = [ 8776 ];
    };
    roles.client = {
      tags.all = { };
      machines."router".settings.routingFeatures = "server";
    };
  };
};
```

## Overview

`netbird` runs a self-hosted NetBird mesh VPN server and connects clan machines as NetBird clients.

Server role:

- imports `self.modules.nixos.netbirdServerStack`
- enables management, signal, relay, dashboard, embedded IdP, and proxy services
- generates relay secret, encryption key, and owner password with clan vars
- configures the dashboard against the public server domain
- configures the NetBird reverse proxy for `proxyDomain`

Client role:

- imports `self.modules.nixos.netbirdClient`
- prompts once for a shared NetBird setup key
- configures `services.netbird.clients.default`
- points management/admin URLs at the server domain
- exports peer host metadata for clan networking
- supports route client/server modes through `routingFeatures`

sshServer role:

- enables the NetBird SSH server on a peer
- must be assigned together with the client role on the same machine: the client
  role reads the sshServer settings and passes `--allow-server-ssh` (plus auth/SFTP
  flags) to `netbird up`; assigning sshServer alone has no effect

## Settings

### `server`

- `domain`: public NetBird server domain, for example `nb.example.com`.
- `proxyDomain`: public proxy domain, for example `proxy.example.com`.
- `port`: WireGuard listen port for clients. defaults to `51820`.
- `proxyTCPPorts`: additional public TCP ports exposed by NetBird TCP services.

### `client`

- `routingFeatures`: NetBird routing mode. one of `none`, `client`, `server`, `both`. defaults to `client`.

### `sshServer`

- `disableAuth`: disable JWT auth for NetBird SSH and rely on NetBird ACLs. defaults to `true`.
- `enableSftp`: enable SFTP for NetBird SSH. defaults to `true`.
