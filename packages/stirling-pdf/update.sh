#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-update nix
# shellcheck shell=bash
set -euo pipefail

FLAKE_ROOT="$PWD"

cd "$FLAKE_ROOT"

if ! nix-update -F stirling-pdf; then
  echo ":: nix-update gradle step failed (expected in flake repos), continuing"
fi

# mitmCache.updateScript uses bwrap; codeberg-medium runner lacks user-ns
# privileges (`bwrap: Can't mount proc on /newroot/proc`). tolerate failure
# in ci; deps.json must be regenerated locally if mitm cache is stale.
script=$(nix build .#stirling-pdf.mitmCache.updateScript --no-link --print-out-paths)
if ! "$script"; then
  echo ":: stirling-pdf mitmCache update failed (likely bwrap sandbox restrictions), continuing"
fi
