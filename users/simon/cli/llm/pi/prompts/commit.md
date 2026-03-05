---
description: commit current work with jj and move bookmark
---

create atomic commit(s) and move main bookmark to tip. do NOT push.

rules:

- one logical change per commit. split unrelated changes.
- commit msg: lowercase, concise, imperative.
- focus msg on why, not what.
- no conventional commit prefixes.
- prefix docs changes with `docs:`.
- ensure working copy ends on a fresh empty change (if last operation was `jj describe`, run `jj new`).
