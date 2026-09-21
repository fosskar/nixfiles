## Usage

```nix
inventory.instances = {
  nix-grpc-store = {
    module = {
      name = "nix-grpc-store";
      input = "self";
    };
    roles.builder.machines."builder" = { };
    roles.client.tags.all = { };
  };
};
```

## Overview

`nix-grpc-store` wires Nix distributed builds over gRPC with mTLS instead
of `ssh-ng`, using [Mic92/nix-grpc-store](https://github.com/Mic92/nix-grpc-store).

Builder role:

- runs `nix-grpc-daemon` in front of the local `nix-daemon` on port 50051
- terminates TLS with a per-machine certificate and requires client
  certificates signed by the clan CA
- `trustClients = true`; access rules grant `trusted` only to the client
  machines' certificate CNs (their machine names)
- enables the build features the advertised `supportedFeatures` need
  (`auto-allocate-uids`, cgroups, `uid-range`, `recursive-nix`) and sets
  `max-jobs` from `maxJobs`

Client role:

- loads the `grpc://` store plugin, enables `nix.distributedBuilds`
- gets a certificate signed by the clan CA, linked to
  `/run/nix-grpc-store/client.{crt,key}` where the plugin looks by default
- adds every builder to `nix.buildMachines` as `grpc://<builder>.<domain>:50051`
  with the CA passed as `ca-cert`

Machines assigned both roles skip the client config.

## Vars

- `nix-grpc-store-ca` (shared): `ca.crt` public, `ca.key` secret and never
  deployed; only used when signing machine certificates
- `nix-grpc-store` (per machine): `cert.pem` public, `key.pem` secret, owned
  by `nix-grpc-daemon` on the builder and root on clients

Certificates are valid for ten years; regenerate with
`clan vars generate --regenerate <machine> --generator nix-grpc-store`.
