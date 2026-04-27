#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl gnused nix jq
# shellcheck shell=bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
file="$SCRIPT_DIR/default.nix"

# prefer RENOVATE_GITHUB_COM_TOKEN (set in ci) > GITHUB_TOKEN (only useful if it's actually a github pat)
gh_token="${RENOVATE_GITHUB_COM_TOKEN:-${GITHUB_TOKEN:-}}"

latest="$(curl --fail -s ${gh_token:+-u ":$gh_token"} \
  "https://api.github.com/repos/BaLaurent/agent-desktop/releases/latest" |
  jq -r '.tag_name | ltrimstr("v")')"

if [[ -z $latest || $latest == "null" ]]; then
  echo "could not determine latest agent-desktop version" >&2
  exit 1
fi

current="$(sed -n 's/.*version = "\([^"]*\)".*/\1/p' "$file" | head -1)"
if [[ $current == "$latest" ]]; then
  echo ":: agent-desktop already at $latest"
  exit 0
fi

url="https://github.com/BaLaurent/agent-desktop/releases/download/v${latest}/agent-desktop-${latest}-x86_64.AppImage"
hash="$(nix-hash --to-sri --type sha256 "$(nix-prefetch-url --type sha256 "$url")")"

tmp="$(mktemp)"
version_done=0
hash_next=0
hash_done=0

while IFS= read -r line; do
  if [[ $version_done -eq 0 && $line =~ ^[[:space:]]*version[[:space:]]*= ]]; then
    printf '  version = "%s";\n' "$latest" >>"$tmp"
    version_done=1
    continue
  fi

  if [[ $line == *'url = "https://github.com/BaLaurent/agent-desktop/releases/download/'* ]]; then
    version_ref='$'"{version}"
    printf '    url = "https://github.com/BaLaurent/agent-desktop/releases/download/v%s/agent-desktop-%s-x86_64.AppImage";\n' "$version_ref" "$version_ref" >>"$tmp"
    hash_next=1
    continue
  fi

  if [[ $hash_next -eq 1 && $hash_done -eq 0 && $line =~ ^[[:space:]]*hash[[:space:]]*= ]]; then
    printf '    hash = "%s";\n' "$hash" >>"$tmp"
    hash_done=1
    hash_next=0
    continue
  fi

  printf '%s\n' "$line" >>"$tmp"
done <"$file"

if [[ $version_done -ne 1 || $hash_done -ne 1 ]]; then
  echo "failed to update agent-desktop version/hash in $file" >&2
  rm -f "$tmp"
  exit 1
fi

mv "$tmp" "$file"
