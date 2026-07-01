#!/usr/bin/env python3
"""Update third-party packages under packages/ and open one PR per group.

Runs as a nixbot scheduled effect (fresh clone, GitToken from
$HERCULES_CI_SECRETS_JSON) or locally against an existing checkout.

Packages released together share a branch/PR: Codeberg's spam filter
rejects a burst of similarly named PRs, which per-package netbird PRs
would trip.
"""

from __future__ import annotations

import argparse
import json
import os
import stat
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import changelog  # noqa: E402
from forge import Codeberg  # noqa: E402

from packages import Package, discover, run, update  # noqa: E402

OWNER = "fosskar"
REPO = "nixfiles"
BASE = "main"
CLONE_URL = f"https://oauth2@codeberg.org/{OWNER}/{REPO}.git"

# pkg -> shared group; unlisted packages are their own group.
PKG_GROUP = {
    "netbird-client": "netbird",
    "netbird-dashboard": "netbird",
    "netbird-proxy": "netbird",
    "netbird-server": "netbird",
}


def read_token() -> str:
    secrets = os.environ.get("HERCULES_CI_SECRETS_JSON")
    if secrets:
        return json.loads(Path(secrets).read_text())["git"]["data"]["token"]
    token = os.environ.get("CODEBERG_TOKEN")
    if not token:
        sys.exit("no token: set CODEBERG_TOKEN or run inside a nixbot effect")
    return token


def setup_git_auth(token: str) -> None:
    """Feed the token via GIT_ASKPASS so it never lands in a remote URL
    (git echoes remote URLs on error; nixbot effect logs are public)."""
    home = Path(os.environ.get("HOME", tempfile.gettempdir()))
    askpass = home / ".git-askpass"
    askpass.write_text('#!/usr/bin/env bash\nprintf "%s\\n" "$GIT_TOKEN"\n')
    askpass.chmod(askpass.stat().st_mode | stat.S_IEXEC)
    os.environ["GIT_ASKPASS"] = str(askpass)
    os.environ["GIT_TERMINAL_PROMPT"] = "0"
    os.environ["GIT_TOKEN"] = token
    run(repo=home, cmd=["git", "config", "--global", "user.name", "nixbot"])
    run(
        repo=home,
        cmd=["git", "config", "--global", "user.email", "nixbot@noreply.codeberg.org"],
    )
    run(repo=home, cmd=["git", "config", "--global", "safe.directory", "*"])


def group_packages(packages: list[Package]) -> dict[str, list[Package]]:
    groups: dict[str, list[Package]] = {}
    for pkg in packages:
        groups.setdefault(PKG_GROUP.get(pkg.name, pkg.name), []).append(pkg)
    return dict(sorted(groups.items()))


def commit_message(group: str, messages: list[str]) -> str:
    if len(messages) == 1:
        return messages[0]
    return f"update {group}\n\n" + "\n\n".join(messages)


def process_group(
    repo: Path, group: str, pkgs: list[Package], forge: Codeberg | None, prs: list[dict]
) -> None:
    branch = f"update-package-{group}"
    run(repo=repo, cmd=["git", "reset", "--hard"])
    run(repo=repo, cmd=["git", "clean", "-fd"])
    run(repo=repo, cmd=["git", "switch", "-C", branch, f"origin/{BASE}"])

    messages: list[str] = []
    for pkg in pkgs:
        try:
            result = update(repo, pkg)
        except subprocess.CalledProcessError as e:
            # One broken updateScript must not block the rest of the group.
            print(f":: {pkg.name} - update failed, skipping: {e}")
            run(repo=repo, cmd=["git", "reset", "--hard"], check=False)
            run(repo=repo, cmd=["git", "clean", "-fd"], check=False)
            continue
        if not result.changed:
            print(f":: {pkg.name} - no update")
            continue
        rel = f"packages/{pkg.name}"
        run(repo=repo, cmd=["nix", "fmt", "--", rel])
        run(repo=repo, cmd=["git", "add", rel])
        messages.append(result.message or f"update {pkg.name}")

    if not messages:
        print(f":: {group} - nothing to commit")
        return

    message = commit_message(group, messages)
    run(repo=repo, cmd=["git", "commit", "-m", message])

    if forge is None:
        print(f":: {group} - dry-run, not pushing\n{message}\n")
        return

    run(repo=repo, cmd=["git", "push", "--force-with-lease", "origin", branch])

    existing = next(
        (p for p in prs if p["head"]["ref"] == branch and p["base"]["ref"] == BASE),
        None,
    )
    if existing is None:
        title = message.splitlines()[0]
        # Inline upstream release notes in the PR body (commit stays terse).
        body = changelog.enrich(message)
        pr = forge.create_pull(title=title, head=branch, base=BASE, body=body)
        prs.append(pr)
        index = pr["number"]
    else:
        index = existing["number"]
    forge.enable_automerge(index)


def main() -> int:
    parser = argparse.ArgumentParser(description="update packages/ and open PRs")
    parser.add_argument(
        "--repo", type=Path, help="operate on an existing checkout instead of cloning"
    )
    parser.add_argument("--package", "-p", help="only this package")
    parser.add_argument(
        "--list", "-l", action="store_true", help="list discovered packages"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="update and commit but do not push/PR"
    )
    args = parser.parse_args()

    tmp: tempfile.TemporaryDirectory[str] | None = None
    if args.repo:
        repo = args.repo.resolve()
    else:
        setup_git_auth(read_token())
        tmp = tempfile.TemporaryDirectory(prefix="update-packages-")
        repo = Path(tmp.name) / "repo"
        run(repo=Path(tmp.name), cmd=["git", "clone", CLONE_URL, str(repo)])

    try:
        packages = discover(repo)
        if args.package:
            packages = [p for p in packages if p.name == args.package]
            if not packages:
                sys.exit(f"package {args.package!r} not found")
        if args.list:
            for pkg in packages:
                print(f"{pkg.name}\t{pkg.method}")
            return 0

        run(repo=repo, cmd=["git", "fetch", "origin", BASE])

        forge: Codeberg | None = None
        prs: list[dict] = []
        if not args.dry_run:
            forge = Codeberg(OWNER, REPO, read_token())
            prs = forge.open_pulls()

        for group, pkgs in group_packages(packages).items():
            process_group(repo, group, pkgs, forge, prs)
    finally:
        if tmp is not None:
            tmp.cleanup()
    return 0


if __name__ == "__main__":
    sys.exit(main())
