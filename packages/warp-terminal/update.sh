#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bash cacert curl jq nix perl gnugrep --pure
#shellcheck shell=bash
set -euo pipefail

pkg_dir=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "$pkg_dir/../.." && pwd)
package_file="$pkg_dir/default.nix"

err() {
  echo "$*" >&2
  exit 1
}

latest_tag() {
  curl -fsSL https://api.github.com/repos/warpdotdev/warp/releases/latest | jq -r .tag_name
}

prefetch_github() {
  local owner=$1 repo=$2 rev=$3
  nix flake prefetch "github:$owner/$repo/$rev" --json 2>/dev/null | jq -r .hash
}

replace_version_and_hash() {
  local version=$1 src_hash=$2
  VERSION=$version SRC_HASH=$src_hash perl -0pi -e '
    s/version = "[^"]+";/version = "$ENV{VERSION}";/ or die "failed to replace version\n";
    s/(repo = "warp";\n    rev = tag;\n    hash = ")[^"]+(";)/$1$ENV{SRC_HASH}$2/ or die "failed to replace warp src hash\n";
  ' "$package_file"
}

replace_fetch_from_github() {
  local repo=$1 rev=$2 hash=$3
  REPO=$repo REV=$rev HASH=$hash perl -0pi -e '
    my $repo = quotemeta $ENV{REPO};
    s/(repo = "$repo";\n    rev = ")[^"]+(";\n    hash = ")[^"]+(";)/$1$ENV{REV}$2$ENV{HASH}$3/ or die "failed to replace $ENV{REPO}\n";
  ' "$package_file"
}

replace_cargo_hash_with_fake() {
  perl -0pi -e 's/cargoHash = (?:"[^"]+"|lib\.fakeHash);/cargoHash = lib.fakeHash;/ or die "failed to replace cargoHash with fake hash\n";' "$package_file"
}

replace_cargo_hash() {
  local cargo_hash=$1
  CARGO_HASH=$cargo_hash perl -0pi -e 's/cargoHash = lib\.fakeHash;/cargoHash = "$ENV{CARGO_HASH}";/ or die "failed to replace fake cargoHash\n";' "$package_file"
}

tag=${1:-$(latest_tag)}
[[ $tag == v* ]] || tag="v$tag"
version=${tag#v}

cargo_toml=$(mktemp)
build_log=$(mktemp)
trap 'rm -f "$cargo_toml" "$build_log"' EXIT

curl -fsSL "https://raw.githubusercontent.com/warpdotdev/warp/$tag/Cargo.toml" -o "$cargo_toml"

proto_rev=$(perl -ne 'print "$1\n" if /warp_multi_agent_api\s*=\s*\{[^}]*rev = "([^"]+)"/' "$cargo_toml")
workflows_rev=$(perl -ne 'print "$1\n" if /warp-workflows\s*=\s*\{[^}]*rev = "([^"]+)"/' "$cargo_toml")

[[ -n $proto_rev ]] || err "could not find warp_multi_agent_api rev in Cargo.toml"
[[ -n $workflows_rev ]] || err "could not find warp-workflows rev in Cargo.toml"

src_hash=$(prefetch_github warpdotdev warp "$tag")
proto_hash=$(prefetch_github warpdotdev warp-proto-apis "$proto_rev")
workflows_hash=$(prefetch_github warpdotdev workflows "$workflows_rev")

replace_version_and_hash "$version" "$src_hash"
replace_fetch_from_github warp-proto-apis "$proto_rev" "$proto_hash"
replace_fetch_from_github workflows "$workflows_rev" "$workflows_hash"
replace_cargo_hash_with_fake

set +e
(
  cd "$repo_root"
  nix build .#warp-terminal --no-link
) >"$build_log" 2>&1
build_status=$?
set -e

cargo_hash=$(awk '/got:/ { print $2; exit }' "$build_log")
[[ -n $cargo_hash ]] || {
  cat "$build_log" >&2
  err "could not extract cargoHash from nix build output"
}

replace_cargo_hash "$cargo_hash"

(
  cd "$repo_root"
  nix fmt
)

echo "warp-terminal updated to $version"

if [[ $build_status -eq 0 ]]; then
  echo "warning: build succeeded while cargoHash was fake; verify cargoHash manually" >&2
fi
