"""Forge REST clients (Codeberg/Gitea, GitHub); stdlib only, retries on rate limit."""

from __future__ import annotations

import json
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any

# sleeps *between* attempts (attempts = len + 1); codeberg's rate-limit
# window is undocumented and its 429s carry no Retry-After, so geometric
# growth probes short burst limits cheaply and still outlasts a
# minutes-scale bucket (185s cumulative before the final attempt).
_BACKOFF = (5, 15, 45, 120)


class ForgeError(Exception):
    def __init__(self, msg: str, status: int | None = None) -> None:
        super().__init__(msg)
        self.status = status


class Forge:
    """Shared request plumbing; subclasses define endpoints and auth."""

    api: str

    def __init__(self, host: str, owner: str, repo: str, token: str) -> None:
        self._token = token

    def _headers(self) -> dict[str, str]:
        raise NotImplementedError

    def _request(
        self, method: str, url: str, body: dict[str, Any] | None = None
    ) -> Any:
        data = json.dumps(body).encode() if body is not None else None
        last_status: int | None = None
        attempts = len(_BACKOFF) + 1
        for attempt, delay in enumerate((*_BACKOFF, None), start=1):
            req = urllib.request.Request(url, data=data, method=method)
            for name, value in self._headers().items():
                req.add_header(name, value)
            if data is not None:
                req.add_header("Content-Type", "application/json")
            try:
                with urllib.request.urlopen(req) as resp:
                    raw = resp.read()
                    return json.loads(raw) if raw else None
            except urllib.error.HTTPError as e:
                if e.code == 429 and delay is not None:
                    last_status = e.code
                    retry_after = e.headers.get("Retry-After")
                    wait = (
                        int(retry_after)
                        if retry_after and retry_after.isdigit()
                        else delay
                    )
                    print(
                        f":: rate limited (attempt {attempt}/{attempts}, "
                        f"{method} {url}), sleeping {wait}s"
                    )
                    time.sleep(wait)
                    continue
                if e.code == 429:
                    last_status = e.code
                    print(f":: rate limited (final attempt {attempt}/{attempts})")
                    break
                detail = e.read().decode(errors="replace")
                msg = f"{method} {url} -> {e.code}: {detail}"
                raise ForgeError(msg, status=e.code) from e
            except urllib.error.URLError as e:
                if delay is None:
                    break
                print(f":: request error ({method} {url}): {e}; retrying in {delay}s")
                time.sleep(delay)
        msg = f"retries exhausted: {method} {url}"
        raise ForgeError(msg, status=last_status)

    def create_pull(
        self, *, title: str, head: str, base: str, body: str
    ) -> dict[str, Any]:
        return self._request(
            "POST",
            f"{self.api}/pulls",
            {"title": title, "head": head, "base": base, "body": body},
        )

    def update_pull(self, index: int, *, title: str, body: str) -> None:
        self._request(
            "PATCH", f"{self.api}/pulls/{index}", {"title": title, "body": body}
        )


class Codeberg(Forge):
    def __init__(self, host: str, owner: str, repo: str, token: str) -> None:
        super().__init__(host, owner, repo, token)
        self.api = f"https://{host}/api/v1/repos/{owner}/{repo}"

    def _headers(self) -> dict[str, str]:
        return {"Authorization": f"token {self._token}"}

    def open_pulls(self) -> list[dict[str, Any]]:
        return self._request("GET", f"{self.api}/pulls?state=open&limit=50") or []

    def merge_if_green(self, index: int) -> None:
        # Forgejo automerge only fires on a *future* status event; checks
        # that finished before enable_automerge (fast CI, rate-limit backoff
        # delaying the schedule call) leave the PR scheduled forever. main is
        # protected (required status: nixbot/nix-build), so this fails
        # harmlessly while checks are pending and succeeds once green.
        try:
            self._request(
                "POST",
                f"{self.api}/pulls/{index}/merge",
                {"Do": "squash", "delete_branch_after_merge": True},
            )
            print(f":: PR {index} - checks already green, merged directly")
        except ForgeError as e:
            # 405 = not mergeable (yet): checks pending or conflicts - the
            # expected outcome when racing CI; automerge or the next run
            # covers it. Anything else (auth, 5xx) must be visible.
            if e.status != 405:
                print(f":: PR {index} - merge attempt failed: {e}")

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


class Github(Forge):
    def __init__(self, host: str, owner: str, repo: str, token: str) -> None:
        super().__init__(host, owner, repo, token)
        self.api = f"https://api.github.com/repos/{owner}/{repo}"

    def _headers(self) -> dict[str, str]:
        return {
            "Authorization": f"Bearer {self._token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        }

    def open_pulls(self) -> list[dict[str, Any]]:
        return self._request("GET", f"{self.api}/pulls?state=open&per_page=50") or []

    # The check run gating direct merges. Mirrors the required status of the
    # Codeberg branch protection; nixbot creates it per push and it succeeds
    # only when every build attribute did.
    REQUIRED_CHECK = "nixbot/nix-build"

    def merge_if_green(self, index: int) -> None:
        # Same green-race unsticking as Codeberg, but GitHub cannot be
        # trusted to reject the merge: branch protection is unavailable on
        # private repos under the free plan, so an unconditional PUT merges
        # anything (nixwork PR #28 merged 96s after creation, hours before
        # nix-build failed). Verify CI ourselves: the aggregate nixbot check
        # run on the PR head must have concluded successfully. A missing run
        # fails closed - nixbot has not reported (or not started) yet.
        # Branch deletion is not a merge parameter on GitHub; the repo's
        # "automatically delete head branches" setting covers it.
        try:
            head = self._request("GET", f"{self.api}/pulls/{index}")["head"]["sha"]
            runs = self._request(
                "GET",
                f"{self.api}/commits/{head}/check-runs"
                f"?check_name={urllib.parse.quote(self.REQUIRED_CHECK, safe='')}",
            ).get("check_runs", [])
            if not any(
                run["status"] == "completed" and run["conclusion"] == "success"
                for run in runs
            ):
                print(f":: PR {index} - {self.REQUIRED_CHECK} not green, not merging")
                return
            # `sha` pins the merge to the verified head; a push racing this
            # check is rejected with 409 instead of merging unverified work.
            self._request(
                "PUT",
                f"{self.api}/pulls/{index}/merge",
                {"merge_method": "squash", "sha": head},
            )
            print(f":: PR {index} - checks already green, merged directly")
        except ForgeError as e:
            # 405 = not mergeable (yet), 409 = head moved during the attempt;
            # both are expected when racing CI and covered by the next run.
            if e.status not in (405, 409):
                print(f":: PR {index} - merge attempt failed: {e}")

    def enable_automerge(self, index: int) -> None:
        # REST cannot enable automerge; the GraphQL mutation needs the PR
        # node id and the repo setting "allow auto-merge". Failure is
        # tolerable either way: sweep/next run merges green PRs directly.
        try:
            node_id = self._request("GET", f"{self.api}/pulls/{index}")["node_id"]
            result = self._request(
                "POST",
                "https://api.github.com/graphql",
                {
                    "query": (
                        "mutation($id: ID!) { enablePullRequestAutoMerge("
                        "input: {pullRequestId: $id, mergeMethod: SQUASH})"
                        " { clientMutationId } }"
                    ),
                    "variables": {"id": node_id},
                },
            )
            errors = (result or {}).get("errors")
            if errors:
                print(f":: automerge request queued or pending: {errors[0]['message']}")
        except ForgeError as e:
            print(f":: automerge request queued or pending: {e}")
