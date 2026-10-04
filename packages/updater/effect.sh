#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
packages | flake-inputs) updater="updater-$1" ;;
*)
  echo "usage: updater-effect packages|flake-inputs [updater args...]" >&2
  exit 2
  ;;
esac
shift

token=$(jq -re '.git.data.token' "$HERCULES_CI_SECRETS_JSON")
export FORGE_TOKEN="$token"
export GITHUB_TOKEN="$token"
export NIX_CONFIG="experimental-features = nix-command flakes
access-tokens = github.com=$token"

git config --global user.name 'fosskar[bot]'
git config --global user.email '300917551+fosskar[bot]@users.noreply.github.com'

git config remote.origin.promisor true
git config remote.origin.partialclonefilter blob:none

# nixbot's mkEffect setup hook writes the state API auth header into $PWD,
# the checkout; unused here and it dirties the tree
rm -f hercules-ci.headers

exec "$updater" "$@"
