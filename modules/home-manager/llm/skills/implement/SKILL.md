---
name: implement
description: "Implement a piece of work based on a spec or task description."
disable-model-invocation: true
---

Implement the work described by the user.

## Proof of correctness

Before coding, identify what proves this repo's changes correct, and run it as you go — the cheap check regularly, the full gate once at the end:

- **Rust** — `cargo test` for the touched crate regularly; full gate = workspace tests, then `nix flake check` (includes NixOS VM tests where the repo has them).
- **Go** — `go test ./...`; e2e suites only when the touched code path demands them.
- **Nix config** — `nix eval` on the exact option for value changes; `nix build .#nixosConfigurations.<machine>.config.system.build.toplevel` for structural/module changes; `nix flake check` where the repo exposes checks.
- **TypeScript** — the repo's test script (e.g. vitest) where one exists; otherwise `nix build` is the gate.
- **Always** — `nix fmt` after nix edits; formatting is part of the flake check.

## Loop

Use the tdd skill where the repo has a test culture, at pre-agreed seams. One slice at a time; run the single test or check that covers the slice after each step.

Once done, run the full gate, then use the code-review skill to review the work against the repo's standards.

Leave the work uncommitted; the user decides when to commit.
