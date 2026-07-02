"""Discover and update packages/<name>: updateScript -> nix-update,
executable update.sh -> run it, neither -> skipped."""

from __future__ import annotations

import json
import re
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path


@dataclass
class Package:
    name: str
    method: str  # "nix-update" or "script"
    path: Path


@dataclass
class UpdateResult:
    name: str
    changed: bool
    message: str | None = None


def run(
    cmd: list[str], repo: Path, check: bool = True
) -> subprocess.CompletedProcess[str]:
    # Stream stdout/stderr straight to the effect log so command output
    # (nix-update errors, git progress) is visible live.
    return subprocess.run(cmd, cwd=repo, text=True, check=check)


def capture(
    cmd: list[str], repo: Path, check: bool = True
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=repo, capture_output=True, text=True, check=check)


def discover(repo: Path) -> list[Package]:
    packages: list[Package] = []
    for pkg_dir in sorted((repo / "packages").iterdir()):
        if not pkg_dir.is_dir():
            continue
        package_nix = pkg_dir / "package.nix"
        update_sh = pkg_dir / "update.sh"
        if package_nix.exists() and re.search(
            r"\bupdateScript\s*=", package_nix.read_text()
        ):
            packages.append(Package(pkg_dir.name, "nix-update", pkg_dir))
        elif update_sh.exists() and update_sh.stat().st_mode & 0o111:
            packages.append(Package(pkg_dir.name, "script", pkg_dir))
    return packages


def _read_version(repo: Path, name: str) -> str | None:
    result = capture(
        repo=repo, cmd=["nix", "eval", "--raw", f".#{name}.version"], check=False
    )
    return result.stdout.strip() if result.returncode == 0 else None


def _git_touched(repo: Path, rel: str) -> bool:
    return bool(
        capture(repo=repo, cmd=["git", "status", "--porcelain", rel]).stdout.strip()
    )


def _update_script_args(repo: Path, name: str) -> list[str]:
    result = capture(repo=repo, cmd=["nix", "eval", "--json", f".#{name}.updateScript"])
    value = json.loads(result.stdout)
    if not isinstance(value, list):
        msg = f"{name}: updateScript is not a list; unsupported form: {value!r}"
        raise RuntimeError(msg)
    return value


def _is_nix_update(arg: str) -> bool:
    return arg == "nix-update" or arg.rsplit("/", 1)[-1] == "nix-update"


def update(repo: Path, pkg: Package) -> UpdateResult:
    rel = f"packages/{pkg.name}"
    if pkg.method == "nix-update":
        # updateScript is `[<nix-update>, <args...>]`; call nix-update with
        # those args. --use-update-script re-runs it in a nix develop shell
        # and fails.
        script = _update_script_args(repo, pkg.name)
        extra = script[1:] if script and _is_nix_update(script[0]) else []
        with tempfile.NamedTemporaryFile("r", suffix=".msg") as msg:
            run(
                repo=repo,
                cmd=[
                    "nix-update",
                    *extra,
                    "--flake",
                    "--write-commit-message",
                    msg.name,
                    pkg.name,
                ],
            )
            message = Path(msg.name).read_text().strip() or None
        changed = _git_touched(repo, rel)
        return UpdateResult(pkg.name, changed, message if changed else None)

    old = _read_version(repo, pkg.name)
    # update.sh has a `#!/usr/bin/env nix` shebang; /usr/bin/env is absent
    # in the effect sandbox, so invoke nix on the script directly.
    run(repo=repo, cmd=["nix", str(pkg.path / "update.sh")])
    changed = _git_touched(repo, rel)
    new = _read_version(repo, pkg.name)
    message = (
        f"{pkg.name}: {old or 'unknown'} -> {new or 'unknown'}" if changed else None
    )
    return UpdateResult(pkg.name, changed, message)
