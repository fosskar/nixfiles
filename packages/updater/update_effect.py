#!/usr/bin/env python3
"""Prepare a nixbot effect checkout, then run one of the updaters in it."""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import update_flake_inputs
import update_packages
from pipeline import run

UPDATERS = {
    "packages": update_packages.main,
    "flake-inputs": update_flake_inputs.main,
}

BOT_NAME = "fosskar[bot]"
BOT_EMAIL = "300917551+fosskar[bot]@users.noreply.github.com"


def setup(repo: Path) -> None:
    secrets = json.loads(Path(os.environ["HERCULES_CI_SECRETS_JSON"]).read_text())
    token = secrets["git"]["data"]["token"]
    os.environ["FORGE_TOKEN"] = token
    os.environ["GITHUB_TOKEN"] = token
    os.environ["NIX_CONFIG"] = (
        f"experimental-features = nix-command flakes\naccess-tokens = github.com={token}"
    )

    run(repo=repo, cmd=["git", "config", "--global", "user.name", BOT_NAME])
    run(repo=repo, cmd=["git", "config", "--global", "user.email", BOT_EMAIL])
    run(repo=repo, cmd=["git", "config", "remote.origin.promisor", "true"])
    run(repo=repo, cmd=["git", "config", "remote.origin.partialclonefilter", "blob:none"])


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] not in UPDATERS:
        sys.exit(f"usage: updater-effect {'|'.join(UPDATERS)} [updater args...]")
    name = sys.argv[1]
    setup(Path.cwd())
    sys.argv = [f"updater-{name}", *sys.argv[2:]]
    return UPDATERS[name]()


if __name__ == "__main__":
    sys.exit(main())
