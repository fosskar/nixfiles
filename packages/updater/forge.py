"""GitHub REST client; stdlib only, retries on rate limit."""

from __future__ import annotations

import json
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any

# sleeps *between* attempts (attempts = len + 1), used when a 429 carries
# no Retry-After; geometric growth probes short burst limits cheaply and
# still outlasts a minutes-scale bucket (185s cumulative before the final
# attempt).
_BACKOFF = (5, 15, 45, 120)
# generous: a stalled connection must not hang the effect, a slow forge
# must not fail it.
TIMEOUT = 120


class ForgeError(Exception):
    def __init__(self, msg: str, status: int | None = None) -> None:
        super().__init__(msg)
        self.status = status


class Forge:
    """Shared request plumbing; subclasses define endpoints and auth."""

    api: str

    def __init__(self, token: str) -> None:
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
                with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
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
            except (urllib.error.URLError, TimeoutError) as e:
                # the server may have acted on a write before the connection
                # failed; retrying could e.g. open a duplicate PR.
                if method != "GET":
                    msg = f"{method} {url}: {e}"
                    raise ForgeError(msg) from e
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


class Github(Forge):
    def __init__(self, host: str, owner: str, repo: str, token: str) -> None:
        super().__init__(token)
        self.api = f"https://api.github.com/repos/{owner}/{repo}"

    def _headers(self) -> dict[str, str]:
        return {
            "Authorization": f"Bearer {self._token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        }

    def open_pulls(self) -> list[dict[str, Any]]:
        return self._request("GET", f"{self.api}/pulls?state=open&per_page=50") or []

    # The check run gating direct merges; nixbot creates it per push and it
    # succeeds only when every build attribute did.
    REQUIRED_CHECK = "nixbot/nix-build"

    def merge_if_green(self, index: int) -> None:
        # GitHub refuses automerge on a PR whose checks already passed;
        # this direct merge unsticks such PRs. GitHub cannot be trusted to
        # reject the merge: branch protection is unavailable on
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
