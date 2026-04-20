#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl gnused nix jq python3
# shellcheck shell=bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
file="$SCRIPT_DIR/default.nix"

latest="$(curl --fail -s ${GITHUB_TOKEN:+-u ":$GITHUB_TOKEN"} \
  "https://api.github.com/repos/BaLaurent/agent-desktop/releases/latest" \
  | jq -r '.tag_name | ltrimstr("v")')"

if [[ -z $latest || $latest == "null" ]]; then
  echo "could not determine latest agent-desktop version" >&2
  exit 1
fi

current="$(sed -n 's/.*version = "\([^"]*\)".*/\1/p' "$file" | head -1)"
if [[ "$current" == "$latest" ]]; then
  echo ":: agent-desktop already at $latest"
  exit 0
fi

url="https://github.com/BaLaurent/agent-desktop/releases/download/v${latest}/agent-desktop-${latest}-x86_64.AppImage"
hash="$(nix-hash --to-sri --type sha256 "$(nix-prefetch-url --type sha256 "$url")")"

python3 - "$file" "$latest" "$hash" <<'PY'
import re, sys
path, version, hash_ = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(path).read()
s = re.sub(r'(\n  version = ")[^"]+(";)', r'\g<1>' + version + r'\g<2>', s, count=1)
s = re.sub(
    r'(url = "https://github\.com/BaLaurent/agent-desktop/releases/download/[^"]+";\s*hash = ")[^"]+(")',
    r'\g<1>' + hash_ + r'\g<2>',
    s, count=1,
)
open(path, 'w').write(s)
PY
