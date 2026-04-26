---
description: commit current work with jj
---

create atomic commit(s). do NOT move bookmarks. do NOT push.

rules:

- one logical change per commit.
- atomic means coherent and easy to review/revert, not maximal splitting.
- if small changes belong to the same task, keep them together.
- split only when changes are unrelated or would be easier to review/revert separately.
- commit msg: lowercase, concise, imperative.
- focus msg on why.
- no conventional commit prefixes.
- docs-only commit msg must start with `docs:`.
- keep it simple.

`jj describe` vs `jj commit`:

- `jj describe -m "..."` = rename current change only.
- `jj commit -m "..."` = finalize current change, creates new empty working change.

flow:

1. inspect
   - `jj status`
   - `jj diff --stat`
2. if changes are clearly unrelated, split by logical file groups
   - `jj split -m "<msg>" -- <paths...>`
3. commit remaining change
   - `jj commit -m "<msg>"`
4. verify clean empty working change
   - `jj status`

guardrails:

- do not move bookmarks in this prompt.
- no `jj restore`, `git restore`, `git checkout --`.
- do not push.
