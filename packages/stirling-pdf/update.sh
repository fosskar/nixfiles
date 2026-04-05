#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-update nix
# shellcheck shell=bash
set -euo pipefail

FLAKE_ROOT="$PWD"

cd "$FLAKE_ROOT"

if ! nix-update -F stirling-pdf; then
  echo ":: nix-update gradle step failed (expected in flake repos), continuing"
fi

script=$(nix build .#stirling-pdf.mitmCache.updateScript --no-link --print-out-paths)
"$script"
