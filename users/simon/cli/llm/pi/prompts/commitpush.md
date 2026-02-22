---
description: commit current work with jj, atomic changes and push to remote
---

create atomic commit(s) and push committed work with jj.

rules:

- one logical change per commit. split unrelated changes.
- commit msg: lowercase, concise, imperative.
- focus msg on why, not what.
- no conventional commit prefixes.
- optional short scope prefix if useful (e.g. cli:, nix:, auth:).
- move `main` bookmark to latest non-empty change
