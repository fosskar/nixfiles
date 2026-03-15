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

# packages with custom version regex (filter out unwanted tags)
declare -A VERSION_REGEX=(
  ["fosrl-newt"]='v?(\d+\.\d+\.\d+)$'
  ["fosrl-pangolin"]='(\d+\.\d+\.\d+)$'
)

# packages that need explicit upstream url (derivation src has no direct url)
declare -A UPDATE_URL=(
  ["agent-desktop"]="https://github.com/BaLaurent/agent-desktop"
  ["arbor"]="https://github.com/penso/arbor"
  ["t3code"]="https://github.com/pingdotgg/t3code"
)

# packages that should use github releases api
GITHUB_RELEASE_PACKAGES=("agent-desktop" "arbor" "t3code")

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
  if [[ -v "VERSION_REGEX[$pkg]" ]]; then
    extra_args+=("--version-regex" "${VERSION_REGEX[$pkg]}")
  fi
  if [[ -v "UPDATE_URL[$pkg]" ]]; then
    extra_args+=("--url" "${UPDATE_URL[$pkg]}")
  fi

  local use_github_releases=false
  for gh_pkg in "${GITHUB_RELEASE_PACKAGES[@]}"; do
    [[ $pkg == "$gh_pkg" ]] && use_github_releases=true && break
  done
  $use_github_releases && extra_args+=("--use-github-releases")

  local is_gradle=false
  for gradle_pkg in "${GRADLE_PACKAGES[@]}"; do
    [[ $pkg == "$gradle_pkg" ]] && is_gradle=true && break
  done

  # nix-update's built-in gradle mitm cache update uses legacy nix-build -A
  # which fails in flake-only repos. for gradle packages, ignore nix-update's
  # failure (it still updates version + src/npm/cargo hashes) and handle
  # gradle deps separately below.
  (cd "$FLAKE_ROOT" && nix-update -F "$pkg" "${extra_args[@]}") || {
    if ! $is_gradle; then
      echo "!! failed to update $pkg"
      return 1
    fi
    echo ":: nix-update gradle step failed (expected in flake repos), continuing..."
  }

  if $is_gradle; then
    echo ":: updating gradle deps for $pkg"
    script=$(cd "$FLAKE_ROOT" && nix build ".#${pkg}.mitmCache.updateScript" --no-link --print-out-paths)
    (cd "$FLAKE_ROOT" && "$script") || {
      echo "!! failed to update gradle deps for $pkg"
      return 1
    }
  fi
}

main() {
  local packages=()
  local excludes=()

  # parse args
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -e | --exclude)
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
