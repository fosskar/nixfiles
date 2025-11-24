# Meta Modules

This directory contains repository-wide metadata helpers that expose
information inferred during the host scan phase.

`default.nix` is imported automatically by `hosts/hosts.nix` (and by
`colmena.nix`) so that every system receives a `config.node` attribute
set before its own modules evaluate. The module:

- Verifies that `nodeContext` and `hostRegistry` are provided via
  `specialArgs`.
- Publishes useful, read-only fields such as the node name, host path,
  secrets directory, parent/guest relationship, and the entire
  `hostRegistry` table.
- Gives downstream modules a single source of truth, so they never need
  to re-scan `hosts/` or reconstruct metadata on their own.

Any additional metadata that should be globally available can be
added to the structure emitted by `hosts/hosts.nix`; the module will
expose it automatically through `config.node`.
