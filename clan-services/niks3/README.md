## Usage

```nix
inventory.instances = {
  niks3 = {
    module = {
      name = "niks3";
      input = "self";
    };
    roles.server.machines."builder" = { };
    roles.client.tags.all = { };
  };
};
```

## Overview

`niks3` runs a self-hosted Nix binary cache backed by a Garage S3 bucket. It also configures clients to use the Garage web endpoint as a substituter.

Garage itself is **not** bundled here. The server role expects a local Garage daemon provided by the `garage` clan-service (the machine must also be a garage `peer`); niks3 provisions its own bucket/key against that cluster using the garage service's `garage-shared` rpc secret and `garage` admin token. This is a deliberate dependency: niks3 self-creates its bucket, but relies on the garage cluster being present.

Server role:

- creates a Garage bucket for cache objects (against the local garage node)
- creates S3 credentials for `niks3`
- enables `services.niks3`
- configures PostgreSQL for `niks3`
- enables `niks3-auto-upload` as a Nix post-build hook
- generates a binary cache signing key and an API token with clan vars
- opens the `niks3` API port and Garage web port

Client role:

- trusts the generated public key
- adds each server's Garage web endpoint as a Nix substituter with priority `1`

## Endpoints

- `5751`: `niks3` API on the server
- `3902`: Garage web endpoint used by clients for cache reads

## Settings

No role settings. Server/client behavior is derived from role assignment.
