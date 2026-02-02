#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-update nix
# shellcheck shell=bash
# update packages in this directory
# usage: ./update.sh [--exclude pkg...] [package...]
# examples:
#   ./update.sh                          # update all packages
#   ./update.sh beszel                   # update specific package
#   ./update.sh newt gerbil              # update multiple packages
#   ./update.sh --exclude stirling-pdf   # update all except stirling-pdf
#   ./update.sh -e foo -e bar            # exclude multiple packages

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_ROOT="$(dirname "$SCRIPT_DIR")"

# packages with subpackages that need --subpackage flag
declare -A SUBPACKAGES=(
  ["beszel"]="webui"
)

# packages to skip (binary releases, manual updates)
SKIP_PACKAGES=("handy" "voquill")

# packages with gradle deps that need mitmCache update
GRADLE_PACKAGES=("stirling-pdf")

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

  # update gradle deps if needed
  for gradle_pkg in "${GRADLE_PACKAGES[@]}"; do
    if [[ $pkg == "$gradle_pkg" ]]; then
      echo ":: updating gradle deps for $pkg"
      script=$(cd "$FLAKE_ROOT" && nix build ".#${pkg}.mitmCache.updateScript" --no-link --print-out-paths)
      (cd "$FLAKE_ROOT" && "$script") || {
        echo "!! failed to update gradle deps for $pkg"
        return 1
      }
    fi
  done
}

main() {
  local packages=()
  local excludes=()

  # parse args
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -e|--exclude)
        shift
        [[ $# -gt 0 ]] && excludes+=("$1")
        shift
        ;;
      *)
        packages+=("$1")
        shift
        ;;
    esac
  done

  # if no packages specified, get all
  if [[ ${#packages[@]} -eq 0 ]]; then
    mapfile -t packages < <(get_all_packages)
  fi

  # filter out excludes
  if [[ ${#excludes[@]} -gt 0 ]]; then
    local filtered=()
    for pkg in "${packages[@]}"; do
      local skip=false
      for ex in "${excludes[@]}"; do
        [[ $pkg == "$ex" ]] && skip=true && break
      done
      $skip || filtered+=("$pkg")
    done
    packages=("${filtered[@]}")
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
