#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-update
# shellcheck shell=bash
# update packages in this directory
# usage: ./update.sh [package...]
# examples:
#   ./update.sh              # update all packages
#   ./update.sh beszel       # update specific package
#   ./update.sh newt gerbil  # update multiple packages

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_ROOT="$(dirname "$SCRIPT_DIR")"

# packages with subpackages that need --subpackage flag
declare -A SUBPACKAGES=(
  ["beszel"]="webui"
)

# packages to skip (binary releases, manual updates)
SKIP_PACKAGES=("handy" "voquill")

get_all_packages() {
  for dir in "$SCRIPT_DIR"/*/; do
    pkg=$(basename "$dir")
    [[ $pkg == "flake-module.nix" ]] && continue
    echo "$pkg"
  done
}

should_skip() {
  local pkg="$1"
  for skip in "${SKIP_PACKAGES[@]}"; do
    [[ $pkg == "$skip" ]] && return 0
  done
  return 1
}

update_package() {
  local pkg="$1"

  if should_skip "$pkg"; then
    echo ":: skipping $pkg (binary release)"
    return 0
  fi

  echo ":: updating $pkg"

  local extra_args=()
  if [[ -v "SUBPACKAGES[$pkg]" ]]; then
    extra_args+=("--subpackage" "${SUBPACKAGES[$pkg]}")
  fi

  (cd "$FLAKE_ROOT" && nix-update -F "$pkg" "${extra_args[@]}") || {
    echo "!! failed to update $pkg"
    return 1
  }
}

main() {
  local packages=()

  if [[ $# -eq 0 ]]; then
    mapfile -t packages < <(get_all_packages)
  else
    packages=("$@")
  fi

  local failed=()
  for pkg in "${packages[@]}"; do
    if ! update_package "$pkg"; then
      failed+=("$pkg")
    fi
  done

  echo
  if [[ ${#failed[@]} -gt 0 ]]; then
    echo "failed: ${failed[*]}"
    exit 1
  else
    echo "done"
  fi
}

main "$@"
