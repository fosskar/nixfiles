"""Inline github release notes for the `Diff:` link nix-update emits."""

from __future__ import annotations

import json
import os
import re
import urllib.error
import urllib.request

_COMPARE = re.compile(
    r"https://github\.com/([^/\s]+)/([^/\s]+)/compare/(\S+?)\.\.\.(\S+)"
)
_TITLE = re.compile(r"^\S+: (\S+) -> (\S+)$")
_cache: dict[tuple[str, str, str], str | None] = {}


def fix_stale_urls(message: str) -> str:
    # nix-update evaluates meta.changelog before bumping the version, so a
    # version-templated changelog URL still points at the old release.
    # Rewrite old -> new version on Changelog: lines only; Diff: URLs are
    # computed post-fetch by nix-update and already correct.
    title = _TITLE.match(message.splitlines()[0])
    if not title:
        return message
    old, new = title.groups()
    if old == new:
        return message
    return "\n".join(
        line.replace(old, new) if line.startswith("Changelog:") else line
        for line in message.splitlines()
    )


def _release_body(owner: str, repo: str, tag: str) -> str | None:
    key = (owner, repo, tag)
    if key in _cache:
        return _cache[key]
    body: str | None = None
    # tag may or may not carry a leading "v"; try both.
    candidates = [tag, tag[1:] if tag.startswith("v") else f"v{tag}"]
    for candidate in candidates:
        url = f"https://api.github.com/repos/{owner}/{repo}/releases/tags/{candidate}"
        headers = {
            "Accept": "application/vnd.github+json",
            "User-Agent": "nixfiles-updater",
        }
        token = os.environ.get("GITHUB_TOKEN")
        if token:
            headers["Authorization"] = f"Bearer {token}"
        req = urllib.request.Request(url, headers=headers)
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
    out = message
    seen: set[tuple[str, str]] = set()
    for owner, repo, _old, new in _COMPARE.findall(message):
        if (repo, new) in seen:
            continue
        seen.add((repo, new))
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
