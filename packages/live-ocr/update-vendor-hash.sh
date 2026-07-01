#!/usr/bin/env bash
set -euo pipefail

# renovate runs this as a postUpgradeTask and strips the env, so restore what
# the nix builds need: the flakes CLI features and, on this multi-user nix,
# NIX_REMOTE=daemon so the build goes through the daemon instead of trying to
# write /nix/store directly (which fails with a store remount error).
export NIX_CONFIG="experimental-features = nix-command flakes"
export NIX_REMOTE=daemon

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
