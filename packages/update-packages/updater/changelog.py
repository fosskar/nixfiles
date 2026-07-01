"""Inline upstream release notes into a PR body.

nix-update only emits a compare link (`Diff: .../compare/vA...vB`). For
github-sourced packages we resolve the new tag's release notes from the
github API and inline them; everything is best-effort and falls back to
the bare message on any failure. Only github is handled because that is
the only forge our packages fetch sources from.
"""

from __future__ import annotations

import json
import re
import urllib.error
import urllib.request

_COMPARE = re.compile(
    r"https://github\.com/([^/\s]+)/([^/\s]+)/compare/(\S+?)\.\.\.(\S+)"
)
_cache: dict[tuple[str, str, str], str | None] = {}


def _release_body(owner: str, repo: str, tag: str) -> str | None:
    key = (owner, repo, tag)
    if key in _cache:
        return _cache[key]
    body: str | None = None
    # Upstreams disagree on the leading "v"; try the tag as-is and toggled.
    candidates = [tag, tag[1:] if tag.startswith("v") else f"v{tag}"]
    for candidate in candidates:
        url = f"https://api.github.com/repos/{owner}/{repo}/releases/tags/{candidate}"
        req = urllib.request.Request(
            url,
            headers={
                "Accept": "application/vnd.github+json",
                "User-Agent": "nixfiles-updater",
            },
        )
        try:
            with urllib.request.urlopen(req) as resp:
                body = (json.load(resp).get("body") or "").strip() or None
            break
        except urllib.error.HTTPError as e:
            if e.code == 404:
                continue
            break
        except urllib.error.URLError:
            break
    _cache[key] = body
    return body


def enrich(message: str, max_len: int = 3000) -> str:
    """Append release notes for each github compare URL found in message."""
    out = message
    for owner, repo, _old, new in _COMPARE.findall(message):
        body = _release_body(owner, repo, new)
        if not body:
            continue
        if len(body) > max_len:
            body = body[:max_len].rstrip() + "\n\n… (truncated)"
        out += (
            f"\n\n<details><summary>{repo} {new} release notes</summary>\n\n"
            f"{body}\n\n</details>"
        )
    return out
