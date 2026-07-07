"""Shared branch/PR/automerge pipeline for both updater entrypoints."""

from __future__ import annotations

import os
import sys
from pathlib import Path

import changelog
from forge import Codeberg, Forge, Github

from packages import capture, run

BASE = "main"


def read_token() -> str:
    token = os.environ.get("FORGE_TOKEN") or os.environ.get("CODEBERG_TOKEN")
    if not token:
        sys.exit("no token: set FORGE_TOKEN (or CODEBERG_TOKEN)")
    return token


def parse_origin(url: str) -> tuple[str, str, str]:
    """(host, owner, repo) from an https or ssh git remote URL."""
    url = url.removesuffix(".git")
    if url.startswith(("http://", "https://")):
        _, _, rest = url.partition("://")
        host, _, path = rest.partition("/")
        host = host.rpartition("@")[2]  # strip oauth2:token@ credentials
    elif "@" in url and ":" in url:  # git@host:owner/repo
        host, _, path = url.rpartition("@")[2].partition(":")
    else:
        sys.exit(f"cannot parse origin remote URL: {url!r}")
    parts = path.strip("/").split("/")
    if len(parts) != 2 or not all(parts):
        sys.exit(f"origin remote is not an owner/repo URL: {url!r}")
    return host, parts[0], parts[1]


def default_branch(repo: Path) -> str:
    # HEAD of the origin remote = the repo's default branch; works in
    # shallow/single-branch clones without any API call.
    out = capture(
        repo=repo, cmd=["git", "ls-remote", "--symref", "origin", "HEAD"], check=False
    ).stdout
    for line in out.splitlines():
        if line.startswith("ref:"):
            return line.split()[1].removeprefix("refs/heads/")
    return "main"


def connect(repo: Path, *, dry_run: bool) -> tuple[Forge | None, list[dict]]:
    global BASE  # noqa: PLW0603 - resolved once per run, read by entrypoints
    # Callers hard-reset the tree per unit; refuse to eat local work.
    if capture(repo=repo, cmd=["git", "status", "--porcelain"]).stdout.strip():
        sys.exit("working tree is dirty; commit or stash first")
    BASE = default_branch(repo)
    run(repo=repo, cmd=["git", "fetch", "origin", BASE])
    if dry_run:
        return None, []
    origin = capture(repo=repo, cmd=["git", "remote", "get-url", "origin"])
    host, owner, name = parse_origin(origin.stdout.strip())
    cls = Github if host == "github.com" else Codeberg
    forge = cls(host, owner, name, read_token())
    return forge, forge.open_pulls()


def publish(
    repo: Path,
    branch: str,
    message: str,
    forge: Forge | None,
    prs: list[dict],
) -> int | None:
    """Push HEAD as `branch`, open/refresh its PR; returns the PR number."""
    name = branch
    if forge is None:
        print(f":: {name} - dry-run, not pushing\n{message}\n")
        return None

    # The effect clone is `--depth 1` of main only, so the remote-tracking
    # ref for a leftover update branch (unmerged PR) is absent: the
    # up-to-date check below would be skipped and --force-with-lease would
    # reject with "stale info" for lack of a lease. Fetch it explicitly;
    # missing branch (first push) is fine.
    run(
        repo=repo,
        cmd=[
            "git",
            "fetch",
            "origin",
            f"+refs/heads/{branch}:refs/remotes/origin/{branch}",
        ],
        check=False,
    )

    # The branch is recreated each run, so the commit hash always differs;
    # compare tree + commit message against the remote branch to avoid a
    # nightly force-push (and CI rerun) when nothing changed. Message is
    # part of the identity so convention changes still refresh the PR;
    # parents are ignored so main moving underneath does not force a re-push.
    remote = capture(
        repo=repo,
        cmd=["git", "rev-parse", "--verify", "--quiet", f"origin/{branch}"],
        check=False,
    )
    if (
        remote.returncode == 0
        and run(
            repo=repo,
            cmd=["git", "diff", "--quiet", f"origin/{branch}", "HEAD"],
            check=False,
        ).returncode
        == 0
        and capture(
            repo=repo, cmd=["git", "log", "-1", "--format=%B", f"origin/{branch}"]
        ).stdout.strip()
        == message.strip()
    ):
        print(f":: {name} - remote branch up to date, skipping push")
        existing = next((p for p in prs if p["head"]["ref"] == branch), None)
        if existing is not None:
            # existing PR whose checks finished before automerge was scheduled
            # (green race) is stuck forever; one targeted attempt unsticks it.
            forge.merge_if_green(existing["number"])
            return None
        # branch was pushed but PR creation failed (e.g. rate limited);
        # fall through to create it now.
    else:
        # Explicit lease value: the effect clone is single-branch, so git has
        # no fetch refspec for this branch and a bare --force-with-lease
        # assumes "must not exist on the remote" - rejecting the push with
        # "stale info" whenever a leftover branch exists (e.g. from an
        # unmerged or manually merged PR), even when the tracking ref matches
        # the remote exactly.
        lease = remote.stdout.strip() if remote.returncode == 0 else ""
        run(
            repo=repo,
            cmd=[
                "git",
                "push",
                f"--force-with-lease=refs/heads/{branch}:{lease}",
                "origin",
                branch,
            ],
        )

    title, _, rest = message.partition("\n\n")
    # rest is empty for single-unit branches; keep the full message
    # so the PR body is not blank.
    body = changelog.enrich(rest or message)

    existing = next(
        (p for p in prs if p["head"]["ref"] == branch and p["base"]["ref"] == BASE),
        None,
    )
    if existing is None:
        pr = forge.create_pull(title=title, head=branch, base=BASE, body=body)
        prs.append(pr)
        index = pr["number"]
    else:
        index = existing["number"]
        forge.update_pull(index, title=title, body=body)
    forge.enable_automerge(index)
    return index


def sweep(forge: Forge | None, indexes: list[int]) -> None:
    # Codeberg rate-limits the merge endpoint hard (observed Retry-After up
    # to 120s), so enable_automerge often lands only after CI went green -
    # and Forgejo automerge fires solely on a *future* status event, leaving
    # the PR scheduled forever. By the end of the run CI is finished; one
    # merge attempt per touched PR either merges it now or no-ops (405).
    if forge is None:
        return
    for index in indexes:
        forge.merge_if_green(index)
