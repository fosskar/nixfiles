---
description: publish committed work to origin and rad
---

publish committed work to `origin` and `rad`. `origin` is source of truth. push only `main`.

remote rules:

- always fetch/rebase from `origin`; never fetch/rebase from `rad`.
- if `origin` or `rad` is not configured, stop and report; do not invent remote config.
- ensure radicle node is running before push to `rad` (`rad node start`) and run `rad sync` after push.

preconditions:

- `@` must be clean; stop if there are uncommitted changes.
- `@-` must be non-empty; stop if empty.

flow:

1. inspect
   - `jj status`
   - `jj log -r 'main | main@origin | main@rad | @ | @-' -n 20`
   - `jj git remote list`
2. fetch source of truth
   - `jj git fetch --remote origin`
3. rebase current stack onto origin main
   - `jj rebase -d main@origin`
4. move local main to latest non-empty local commit
   - `jj bookmark set main -r @-`
5. ensure radicle node is running
   - `rad node start` (idempotent: no-op if already running).
6. push only main to origin
   - `jj git push --remote origin --bookmark main`
7. push only main to rad
   - `jj git push --remote rad --bookmark main`
8. sync radicle state to seeds
   - `rad sync`
9. verify
   - `jj status`
   - `jj log -r 'main | main@origin | main@rad | @ | @-' -n 20`

guardrails:

- never set `main` to `@` when `@` is empty.
- on push reject:
  - `origin`: refetch origin, `jj rebase -d main@origin`, push origin again once, then continue to rad only if origin succeeds.
  - `rad`: stop and report — rad should not diverge from origin. do not force.
