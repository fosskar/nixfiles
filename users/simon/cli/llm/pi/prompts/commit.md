---
description: commit current work with jj, atomic changes
---

create atomic commit(s) with jj.

rules:

- one logical change per commit. split unrelated changes.
- commit msg: lowercase, concise, imperative.
- focus msg on why, not what.
- no conventional commit prefixes.
- optional short scope prefix if useful (e.g. cli:, nix:, auth:).

flow:

1. inspect `jj status` + `jj diff --stat`
2. if mixed changes, split with `jj split`
3. commit each atomic change with `jj commit -m "..."`
4. show `jj log -n 6`
