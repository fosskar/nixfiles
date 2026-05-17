from __future__ import annotations

import json
from pathlib import Path
from typing import Any


Lock = dict[str, Any]


def read_lock(path: Path) -> Lock:
    with path.open() as handle:
        return json.load(handle)


def root_inputs(lock: Lock) -> list[str]:
    return sorted(lock["nodes"]["root"].get("inputs", {}).keys())


def locked_node(lock: Lock, input_name: str) -> dict[str, Any] | None:
    node_name = lock["nodes"]["root"].get("inputs", {}).get(input_name)
    if not node_name:
        return None
    return lock["nodes"].get(node_name)


def locked_ref(lock: Lock, input_name: str) -> str:
    node = locked_node(lock, input_name) or {}
    locked = node.get("locked", {})
    value = locked.get("rev") or locked.get("narHash") or locked.get("lastModified") or "unknown"
    return str(value)


def short_ref(value: str, length: int = 12) -> str:
    if value.startswith("sha256-"):
        return value.removeprefix("sha256-")[:length]
    return value[:length]
