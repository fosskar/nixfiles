from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
from collections.abc import Iterator
from contextlib import contextmanager
from pathlib import Path


def run(
    args: list[str], cwd: Path | None = None, env: dict[str, str] | None = None
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, cwd=cwd, env=env, text=True, check=True)


def has_changes(cwd: Path) -> bool:
    result = subprocess.run(
        ["git", "status", "--porcelain"],
        cwd=cwd,
        text=True,
        check=True,
        stdout=subprocess.PIPE,
    )
    return bool(result.stdout.strip())


@contextmanager
def worktree(branch: str, base: str) -> Iterator[Path]:
    temp_dir = Path(tempfile.mkdtemp(prefix="flake-update-"))
    path = temp_dir / branch
    try:
        run(["git", "fetch", "origin", base])
        run(["git", "worktree", "add", "-B", branch, str(path), f"origin/{base}"])
        yield path
    finally:
        subprocess.run(["git", "worktree", "remove", "--force", str(path)], check=False)
        shutil.rmtree(temp_dir, ignore_errors=True)


def commit_all(
    cwd: Path,
    message: str,
    author_name: str,
    author_email: str,
    committer_name: str,
    committer_email: str,
) -> bool:
    if not has_changes(cwd):
        return False
    run(["git", "add", "flake.lock"], cwd=cwd)
    env = os.environ.copy()
    env.update(
        {
            "GIT_AUTHOR_NAME": author_name,
            "GIT_AUTHOR_EMAIL": author_email,
            "GIT_COMMITTER_NAME": committer_name,
            "GIT_COMMITTER_EMAIL": committer_email,
        }
    )
    run(["git", "commit", "-m", message], cwd=cwd, env=env)
    return True


def push_force(cwd: Path, branch: str) -> None:
    run(["git", "push", "origin", "--force", branch], cwd=cwd)
