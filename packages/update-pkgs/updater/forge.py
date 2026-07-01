"""Codeberg (Gitea) REST client; stdlib only, retries on rate limit."""

from __future__ import annotations

import json
import time
import urllib.error
import urllib.request
from typing import Any

_BACKOFF = (5, 15, 45, 120)


class ForgeError(Exception):
    pass


class Codeberg:
    def __init__(self, owner: str, repo: str, token: str) -> None:
        self.api = f"https://codeberg.org/api/v1/repos/{owner}/{repo}"
        self._token = token

    def _request(
        self, method: str, url: str, body: dict[str, Any] | None = None
    ) -> Any:
        data = json.dumps(body).encode() if body is not None else None
        for delay in _BACKOFF:
            req = urllib.request.Request(url, data=data, method=method)
            req.add_header("Authorization", f"token {self._token}")
            if data is not None:
                req.add_header("Content-Type", "application/json")
            try:
                with urllib.request.urlopen(req) as resp:
                    raw = resp.read()
                    return json.loads(raw) if raw else None
            except urllib.error.HTTPError as e:
                if e.code == 429:
                    retry_after = e.headers.get("Retry-After")
                    wait = (
                        int(retry_after)
                        if retry_after and retry_after.isdigit()
                        else delay
                    )
                    print(f":: rate limited ({method} {url}), sleeping {wait}s")
                    time.sleep(wait)
                    continue
                detail = e.read().decode(errors="replace")
                msg = f"{method} {url} -> {e.code}: {detail}"
                raise ForgeError(msg) from e
            except urllib.error.URLError as e:
                print(f":: request error ({method} {url}): {e}; retrying in {delay}s")
                time.sleep(delay)
        msg = f"retries exhausted: {method} {url}"
        raise ForgeError(msg)

    def open_pulls(self) -> list[dict[str, Any]]:
        return self._request("GET", f"{self.api}/pulls?state=open&limit=50") or []

    def create_pull(
        self, *, title: str, head: str, base: str, body: str
    ) -> dict[str, Any]:
        return self._request(
            "POST",
            f"{self.api}/pulls",
            {"title": title, "head": head, "base": base, "body": body},
        )

    def enable_automerge(self, index: int) -> None:
        try:
            self._request(
                "POST",
                f"{self.api}/pulls/{index}/merge",
                {
                    "Do": "squash",
                    "merge_when_checks_succeed": True,
                    "delete_branch_after_merge": True,
                },
            )
        except ForgeError as e:
            print(f":: automerge request queued or pending: {e}")
