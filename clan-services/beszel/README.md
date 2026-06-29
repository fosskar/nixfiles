## Usage

```nix
inventory.instances = {
  beszel = {
    module = {
      name = "beszel";
      input = "self";
    };
    roles.server.machines."server" = { };
    roles.client.tags.server = { };
    roles.client.machines."server".settings = {
      filesystem = "/persist";
      extraFilesystems = "/nix__Nix,/tank__Tank";
      smartDevices = "/dev/nvme0,/dev/sda";
    };
  };
};
```

## Overview

`beszel` runs a Beszel hub and declaratively configures Beszel agents as monitored systems.

Server role:

- enables the Beszel hub on `127.0.0.1:8090`
- writes hub `config.yml` from client role assignments
- exposes the hub through Caddy at `beszel.<local-domain>`
- adds Authelia OIDC client config
- adds Homepage and Gatus entries when those services are enabled
- creates `clan.core.state.beszel-hub` SQLite backups for borgbackup

Client role:

- enables `services.beszel.agent`
- prompts for the agent SSH public key used by the hub
- opens the agent port on `ygg` for non-server machines
- passes filesystem, sensor, SMART, and Podman settings to the agent

## Settings

### `client`

- `host`: override host written to hub `config.yml`. defaults to `<machine>.<clan-domain>` or `127.0.0.1` for the hub machine.
- `port`: Beszel agent listen port. defaults to `18876` (below the ephemeral range so it is never claimed as an outbound source port; beszel's own default 45876 sits inside `net.ipv4.ip_local_port_range`).
- `sensors`: sensors to exclude, for example `-nct6798_cputin`.
- `filesystem`: primary filesystem shown by Beszel. defaults to `/`.
- `extraFilesystems`: extra filesystems in Beszel format, for example `/nix__Nix,/tank__Tank`.
- `smartDevices`: SMART devices passed to the agent, for example `/dev/nvme0,/dev/sda`.
