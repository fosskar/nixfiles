"""Shared branch/PR/automerge pipeline for both updater entrypoints."""

from __future__ import annotations

import os
import sys
from pathlib import Path

import changelog
from forge import Codeberg

from packages import capture, run

OWNER = "fosskar"
REPO = "nixfiles"
BASE = "main"


def read_token() -> str:
    token = os.environ.get("FORGE_TOKEN") or os.environ.get("CODEBERG_TOKEN")
    if not token:
        sys.exit("no token: set FORGE_TOKEN (or CODEBERG_TOKEN)")
    return token


def connect(repo: Path, *, dry_run: bool) -> tuple[Codeberg | None, list[dict]]:
    # Callers hard-reset the tree per unit; refuse to eat local work.
    if capture(repo=repo, cmd=["git", "status", "--porcelain"]).stdout.strip():
        sys.exit("working tree is dirty; commit or stash first")
    run(repo=repo, cmd=["git", "fetch", "origin", BASE])
    if dry_run:
        return None, []
    forge = Codeberg(OWNER, REPO, read_token())
    return forge, forge.open_pulls()


def publish(
    repo: Path,
    branch: str,
    message: str,
    forge: Codeberg | None,
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
        # existing PR whose checks finished before automerge was scheduled
        # (green race) is stuck forever; one targeted attempt unsticks it.
        existing = next((p for p in prs if p["head"]["ref"] == branch), None)
        if existing is not None:
            forge.merge_if_green(existing["number"])
        return None

    # Explicit lease value: the effect clone is single-branch, so git has no
    # fetch refspec for this branch and a bare --force-with-lease assumes
    # "must not exist on the remote" - rejecting the push with "stale info"
    # whenever a leftover branch exists (e.g. from an unmerged or manually
    # merged PR), even when the tracking ref matches the remote exactly.
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


def sweep(forge: Codeberg | None, indexes: list[int]) -> None:
    # Codeberg rate-limits the merge endpoint hard (observed Retry-After up
    # to 120s), so enable_automerge often lands only after CI went green -
    # and Forgejo automerge fires solely on a *future* status event, leaving
    # the PR scheduled forever. By the end of the run CI is finished; one
    # merge attempt per touched PR either merges it now or no-ops (405).
    if forge is None:
        return
    for index in indexes:
        forge.merge_if_green(index)
