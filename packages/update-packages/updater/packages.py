"""Package discovery and version updates for packages/<name>.

Update mechanism mirrors the repo convention:
- package.nix with a `updateScript` attr -> `nix-update -u`
- executable update.sh (no updateScript)    -> run it directly
- neither                                    -> skipped

nix-update writes a commit message (`pkg: old -> new` plus a changelog /
compare link) which we reuse as the commit body.
"""

from __future__ import annotations

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
    message: str | None = None  # commit message incl. changelog, if any


def run(
    cmd: list[str], cwd: Path, check: bool = True
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, check=check)


def discover(repo: Path) -> list[Package]:
    packages: list[Package] = []
    for pkg_dir in sorted((repo / "packages").iterdir()):
        if not pkg_dir.is_dir():
            continue
        package_nix = pkg_dir / "package.nix"
        update_sh = pkg_dir / "update.sh"
        if package_nix.exists() and "updateScript" in package_nix.read_text():
            packages.append(Package(pkg_dir.name, "nix-update", pkg_dir))
        elif update_sh.exists() and update_sh.stat().st_mode & 0o111:
            packages.append(Package(pkg_dir.name, "script", pkg_dir))
    return packages


def _read_version(repo: Path, name: str) -> str | None:
    result = run(
        repo=repo, cmd=["nix", "eval", "--raw", f".#{name}.version"], check=False
    )
    return result.stdout.strip() if result.returncode == 0 else None


def _git_touched(repo: Path, rel: str) -> bool:
    return bool(
        run(repo=repo, cmd=["git", "status", "--porcelain", rel]).stdout.strip()
    )


def update(repo: Path, pkg: Package) -> UpdateResult:
    rel = f"packages/{pkg.name}"
    if pkg.method == "nix-update":
        with tempfile.NamedTemporaryFile("r", suffix=".msg") as msg:
            run(
                repo=repo,
                cmd=[
                    "nix-update",
                    pkg.name,
                    "--flake",
                    "--use-update-script",
                    "--write-commit-message",
                    msg.name,
                ],
            )
            message = Path(msg.name).read_text().strip() or None
        changed = _git_touched(repo, rel)
        return UpdateResult(pkg.name, changed, message if changed else None)

    old = _read_version(repo, pkg.name)
    run(repo=repo, cmd=[str(pkg.path / "update.sh")])
    changed = _git_touched(repo, rel)
    new = _read_version(repo, pkg.name)
    message = (
        f"{pkg.name}: {old or 'unknown'} -> {new or 'unknown'}" if changed else None
    )
    return UpdateResult(pkg.name, changed, message)
