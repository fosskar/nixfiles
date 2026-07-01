#!/usr/bin/env python3
"""Update packages/ sources and open one Codeberg PR per group."""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import changelog  # noqa: E402
from forge import Codeberg  # noqa: E402

from packages import Package, discover, run, update  # noqa: E402

OWNER = "fosskar"
REPO = "nixfiles"
BASE = "main"


def read_token() -> str:
    token = os.environ.get("FORGE_TOKEN") or os.environ.get("CODEBERG_TOKEN")
    if not token:
        sys.exit("no token: set FORGE_TOKEN (or CODEBERG_TOKEN)")
    return token


def group_packages(packages: list[Package]) -> dict[str, list[Package]]:
    # Packages sharing a name prefix (netbird-*, nextcloud-*) go in one
    # branch/PR: Codeberg's anti-spam rejects a burst of similar PRs.
    # Singletons keep their full name.
    by_prefix: dict[str, list[Package]] = {}
    for pkg in packages:
        by_prefix.setdefault(pkg.name.split("-", 1)[0], []).append(pkg)
    groups: dict[str, list[Package]] = {}
    for prefix, members in by_prefix.items():
        key = prefix if len(members) > 1 else members[0].name
        groups[key] = members
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
        "--repo", type=Path, default=Path.cwd(), help="checkout to operate on"
    )
    parser.add_argument("--package", "-p", help="only this package")
    parser.add_argument(
        "--list", "-l", action="store_true", help="list discovered packages"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="update and commit but do not push/PR"
    )
    args = parser.parse_args()
    repo = args.repo.resolve()

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
    return 0


if __name__ == "__main__":
    sys.exit(main())
