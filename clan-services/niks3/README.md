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

Garage itself is **not** bundled here. The server role expects a local Garage daemon provided by the `garage` clan-service (the machine must also be a garage `node`). The cache bucket is declared in the garage instance's `roles.node.settings.buckets` as `niks3-cache` (with `website` and the server's `<machine>.s` alias); niks3 only consumes the pre-generated `garage-buckets` key for it.

Server role:

- consumes the `niks3-cache` bucket and its pre-generated `garage-buckets` key
  (a private niks3-owned copy via the `niks3-s3` vars generator)
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
