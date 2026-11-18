## Usage

```nix
inventory.instances = {
  harmonia = {
    module = {
      name = "harmonia";
      input = "self";
    };
    roles.server.machines."builder".settings = {
      port = 5000;
    };
    roles.client.tags.all = { };
  };
};
```

## Overview

`harmonia` serves a machine's local Nix store as a binary cache and configures clients to use it as a substituter.

Server role:

- enables `services.harmonia.cache`
- generates a per-machine binary cache signing key `<instance>-<machine>-1` with clan vars
- opens the Harmonia TCP port
- signs cache paths with the generated private key

Client role:

- trusts each server's public key
- adds each server as a Nix substituter with priority `3`

## Settings

### `server`

- `port`: Harmonia listen port. defaults to `5000`.

### `client`

No settings. Clients discover server machines from the same clan service instance.
