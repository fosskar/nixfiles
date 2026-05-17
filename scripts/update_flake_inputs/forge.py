from __future__ import annotations

import json
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from typing import Any


class ForgeError(Exception):
    def __init__(self, status: int, message: str) -> None:
        super().__init__(message)
        self.status = status


@dataclass(frozen=True)
class PullRequest:
    number: int
    html_url: str
    head: str
    base: str


class Forgejo:
    def __init__(self, server_url: str, repository: str, token: str) -> None:
        self.server_url = server_url.rstrip("/")
        self.repository = repository.strip("/")
        self.token = token
        self.api_url = f"{self.server_url}/api/v1"

    def request(self, method: str, path: str, data: dict[str, Any] | None = None) -> Any:
        body = None if data is None else json.dumps(data).encode()
        request = urllib.request.Request(
            f"{self.api_url}{path}",
            data=body,
            method=method,
            headers={
                "Accept": "application/json",
                "Authorization": f"token {self.token}",
                "Content-Type": "application/json",
                "User-Agent": "nixfiles-update-flake-inputs",
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=60) as response:  # noqa: S310
                payload = response.read()
        except urllib.error.HTTPError as error:
            payload = error.read().decode(errors="replace")
            raise ForgeError(error.code, payload) from error
        if not payload:
            return None
        return json.loads(payload)

    def check_auth(self) -> None:
        self.request("GET", "/user")
        self.request("GET", f"/repos/{self.repository}")

    def list_open_pr_heads(self) -> set[str]:
        heads: set[str] = set()
        page = 1
        while True:
            prs = self.request(
                "GET",
                f"/repos/{self.repository}/pulls?state=open&limit=50&page={page}",
            )
            if not prs:
                return heads
            for pr in prs:
                head = pr.get("head", {}).get("ref")
                if head:
                    heads.add(head)
            page += 1

    def find_open_pr(self, branch: str, base: str) -> PullRequest | None:
        page = 1
        while True:
            prs = self.request(
                "GET",
                f"/repos/{self.repository}/pulls?state=open&limit=50&page={page}",
            )
            if not prs:
                return None
            for pr in prs:
                head = pr.get("head", {}).get("ref")
                pr_base = pr.get("base", {}).get("ref")
                if head == branch and pr_base == base:
                    return PullRequest(
                        number=pr["number"],
                        html_url=pr["html_url"],
                        head=head,
                        base=pr_base,
                    )
            page += 1

    def create_pull_request(self, branch: str, base: str, title: str, body: str) -> PullRequest:
        pr = self.request(
            "POST",
            f"/repos/{self.repository}/pulls",
            {
                "base": base,
                "head": branch,
                "title": title,
                "body": body,
            },
        )
        return PullRequest(
            number=pr["number"],
            html_url=pr["html_url"],
            head=pr["head"]["ref"],
            base=pr["base"]["ref"],
        )

    def merge_pull_request(self, number: int) -> None:
        self.request(
            "POST",
            f"/repos/{self.repository}/pulls/{number}/merge",
            {"delete_branch_after_merge": True},
        )

    def list_branches(self) -> list[str]:
        branches: list[str] = []
        page = 1
        while True:
            data = self.request(
                "GET",
                f"/repos/{self.repository}/branches?limit=50&page={page}",
            )
            if not data:
                return branches
            branches.extend(branch["name"] for branch in data)
            page += 1

    def delete_branch(self, branch: str) -> None:
        quoted = urllib.parse.quote(branch, safe="")
        self.request("DELETE", f"/repos/{self.repository}/branches/{quoted}")
