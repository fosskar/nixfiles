#!/usr/bin/env bash
set -euo pipefail

pkg=packages/live-ocr/package.nix

sed -i -E 's/vendorHash = "sha256-[^"]+";/vendorHash = lib.fakeHash;/' "$pkg"

set +e
output=$(nix build .#live-ocr -L 2>&1)
status=$?
set -e

hash=$(printf '%s\n' "$output" | sed -n 's/.*got:[[:space:]]*//p' | tail -n1)

if [[ -z $hash ]]; then
  printf '%s\n' "$output" >&2
  exit "$status"
fi

sed -i "s|vendorHash = lib\.fakeHash;|vendorHash = \"$hash\";|" "$pkg"

nix build .#live-ocr -L
