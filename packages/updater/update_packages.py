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
import pipeline  # noqa: E402

from packages import Package, discover, run, update  # noqa: E402


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


def process_group(  # noqa: PLR0913
    repo: Path,
    group: str,
    pkgs: list[Package],
    forge: pipeline.Codeberg | None,
    prs: list[dict],
) -> int | None:
    branch = f"update-package-{group}"
    run(repo=repo, cmd=["git", "reset", "--hard"])
    run(repo=repo, cmd=["git", "clean", "-fd"])
    run(repo=repo, cmd=["git", "switch", "-C", branch, f"origin/{pipeline.BASE}"])

    messages: list[str] = []
    for pkg in pkgs:
        try:
            result = update(repo, pkg)
        except subprocess.CalledProcessError:
            print(f":: {pkg.name} - update failed (see error above), skipping")
            run(repo=repo, cmd=["git", "reset", "--hard"], check=False)
            run(repo=repo, cmd=["git", "clean", "-fd"], check=False)
            continue
        if not result.changed:
            print(f":: {pkg.name} - no update")
            continue
        rel = f"packages/{pkg.name}"
        run(repo=repo, cmd=["nix", "fmt", "--", rel])
        run(repo=repo, cmd=["git", "add", rel])
        # nix fmt can normalize an update.sh rewrite back to the committed
        # content, leaving nothing staged.
        staged = run(
            repo=repo,
            cmd=["git", "diff", "--cached", "--quiet", "--", rel],
            check=False,
        )
        if staged.returncode == 0:
            print(f":: {pkg.name} - no update")
            continue
        messages.append(
            changelog.fix_stale_urls(result.message)
            if result.message
            else f"update {pkg.name}"
        )

    if not messages:
        return None

    message = commit_message(group, messages)
    run(repo=repo, cmd=["git", "commit", "-m", message])
    return pipeline.publish(repo, branch, message, forge, prs)


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

    forge, prs = pipeline.connect(repo, dry_run=args.dry_run)

    # Isolate each group: one failing package/group must not abort the
    # rest of the run. All groups are attempted; a failure still fails the
    # run (red) so it is visible, without blocking the others.
    failures: list[str] = []
    touched: list[int] = []
    for group, pkgs in group_packages(packages).items():
        try:
            index = process_group(repo, group, pkgs, forge, prs)
            if index is not None:
                touched.append(index)
        except Exception as e:  # noqa: BLE001
            print(f":: {group} - FAILED, skipping: {e}")
            failures.append(group)

    # automerge scheduled after CI already went green never fires (Forgejo
    # is event-driven; the merge endpoint's rate-limit backoff makes that
    # the common case here). CI is done by now: merge whatever is green.
    pipeline.sweep(forge, touched)

    if failures:
        print(f":: {len(failures)} group(s) failed: {', '.join(failures)}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
