#!/usr/bin/env python3
"""Update flake inputs across all flake.nix files, one Codeberg PR per input."""

from __future__ import annotations

import argparse
import fnmatch
import json
import os
import sys
from dataclasses import dataclass
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import pipeline  # noqa: E402

from packages import run  # noqa: E402

_IGNORED_DIRS = {".git", "node_modules", "__pycache__"}


@dataclass
class FlakeInput:
    flake_dir: str  # relative to repo root, "." for the root flake
    name: str

    @property
    def unit(self) -> str:
        return self.name if self.flake_dir == "." else f"{self.flake_dir}#{self.name}"

    @property
    def branch(self) -> str:
        slug = self.unit.replace("/", "-").replace("#", "-")
        return f"update-flake-input-{slug}"


def _root_inputs(lock_path: Path) -> list[str]:
    lock = json.loads(lock_path.read_text())
    root = lock["nodes"][lock["root"]]
    # follows-indirection values are path lists, not node keys: nothing to update
    return sorted(k for k, v in root.get("inputs", {}).items() if isinstance(v, str))


def _excluded(unit: str, patterns: list[str]) -> bool:
    return any(fnmatch.fnmatch(unit, p) for p in patterns)


def discover_inputs(repo: Path, exclude: list[str]) -> list[FlakeInput]:
    """Every root input of every flake.nix with a lock file, exclusions applied.

    Exclude patterns match the unit name: `<name>` for the root flake,
    `<dir>#<name>` for nested flakes; `<dir>#*` excludes a whole flake.
    """
    found: list[FlakeInput] = []
    for flake_nix in sorted(repo.rglob("flake.nix")):
        if _IGNORED_DIRS.intersection(flake_nix.parts):
            continue
        lock_path = flake_nix.parent / "flake.lock"
        if not lock_path.exists():
            print(f":: {flake_nix.relative_to(repo)} - no lock file, skipping")
            continue
        flake_dir = str(flake_nix.parent.relative_to(repo))
        found.extend(
            inp
            for name in _root_inputs(lock_path)
            if not _excluded((inp := FlakeInput(flake_dir, name)).unit, exclude)
        )
    return found


def _locked_rev(repo: Path, inp: FlakeInput) -> dict | None:
    lock = json.loads((repo / inp.flake_dir / "flake.lock").read_text())
    node_key = lock["nodes"][lock["root"]]["inputs"][inp.name]
    if not isinstance(node_key, str):
        return None
    return lock["nodes"][node_key].get("locked")


def commit_message(inp: FlakeInput, old: dict | None, new: dict | None) -> str:
    msg = f"flake: update {inp.unit}"
    if not (old and new):
        return msg
    old_rev, new_rev = old.get("rev"), new.get("rev")
    if old_rev and new_rev and old.get("type") == "github":
        compare = (
            f"https://github.com/{old['owner']}/{old['repo']}"
            f"/compare/{old_rev}...{new_rev}"
        )
        msg += f"\n\nDiff: {compare}"
    return msg


def process_input(
    repo: Path, inp: FlakeInput, forge: pipeline.Codeberg | None, prs: list[dict]
) -> int | None:
    run(repo=repo, cmd=["git", "reset", "--hard"])
    run(repo=repo, cmd=["git", "clean", "-fd"])
    run(repo=repo, cmd=["git", "switch", "-C", inp.branch, f"origin/{pipeline.BASE}"])

    lock_rel = f"{inp.flake_dir}/flake.lock" if inp.flake_dir != "." else "flake.lock"
    old = _locked_rev(repo, inp)
    run(repo=repo / inp.flake_dir, cmd=["nix", "flake", "update", inp.name])
    if (
        run(
            repo=repo, cmd=["git", "diff", "--quiet", "--", lock_rel], check=False
        ).returncode
        == 0
    ):
        print(f":: {inp.unit} - no update")
        return None
    new = _locked_rev(repo, inp)

    message = commit_message(inp, old, new)
    run(repo=repo, cmd=["git", "commit", "-m", message, "--", lock_rel])
    return pipeline.publish(repo, inp.branch, message, forge, prs)


def main() -> int:
    parser = argparse.ArgumentParser(description="update flake inputs and open PRs")
    parser.add_argument(
        "--repo", type=Path, default=Path.cwd(), help="checkout to operate on"
    )
    parser.add_argument("--input", "-i", help="only this input (unit name)")
    parser.add_argument(
        "--exclude",
        action="append",
        default=[],
        help="glob on unit name; repeatable (e.g. 'templates/*#*')",
    )
    parser.add_argument("--list", "-l", action="store_true", help="list flake inputs")
    parser.add_argument(
        "--dry-run", action="store_true", help="update and commit but do not push/PR"
    )
    args = parser.parse_args()
    repo = args.repo.resolve()

    inputs = discover_inputs(repo, args.exclude)
    if args.input:
        inputs = [i for i in inputs if i.unit == args.input]
        if not inputs:
            sys.exit(f"input {args.input!r} not found")
    if args.list:
        print("\n".join(i.unit for i in inputs))
        return 0

    forge, prs = pipeline.connect(repo, dry_run=args.dry_run)

    failures: list[str] = []
    touched: list[int] = []
    for inp in inputs:
        try:
            index = process_input(repo, inp, forge, prs)
            if index is not None:
                touched.append(index)
        except Exception as e:  # noqa: BLE001
            print(f":: {inp.unit} - FAILED, skipping: {e}")
            failures.append(inp.unit)

    # automerge scheduled after CI already went green never fires (Forgejo
    # is event-driven; the merge endpoint's rate-limit backoff makes that
    # the common case here). CI is done by now: merge whatever is green.
    pipeline.sweep(forge, touched)

    if failures:
        print(f":: {len(failures)} input(s) failed: {', '.join(failures)}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
