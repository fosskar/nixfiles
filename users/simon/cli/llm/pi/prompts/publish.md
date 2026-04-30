---
description: publish committed work to remote (default origin)
argument-hint: "[remote]"
---

publish committed work to target remote. `origin` is source of truth. push only `main`.

argument:

- target remote is `$1`; if blank, use `origin`.
- accepted values: `origin` or `rad`.
- when running commands, replace `<target-remote>` with selected target.

remote rules:

- always fetch/rebase from `origin`; never fetch/rebase from `rad`.
- if target remote is not configured, stop and report; do not invent remote config.
- if target remote is `rad`, ensure radicle node is running before push (`rad node start`) and run `rad sync` after push.

preconditions:

- `@` must be clean; stop if there are uncommitted changes.
- `@-` must be non-empty; stop if empty.

flow:

1. inspect
   - `jj status`
   - `jj log -r 'main | main@<target-remote> | @ | @-' -n 20`
2. fetch source of truth
   - `jj git fetch --remote origin`
3. rebase current stack onto origin main
   - `jj rebase -d main@origin`
4. move local main to latest non-empty local commit
   - `jj bookmark set main -r @-`
5. rad only: ensure node is running
   - `rad node start` (idempotent: no-op if already running).
6. push only main
   - `jj git push --remote <target-remote> --bookmark main`
7. rad only: sync radicle state to seeds
   - `rad sync`
8. verify
   - `jj status`
   - `jj log -r 'main | main@<target-remote> | @ | @-' -n 20`

guardrails:

- never set `main` to `@` when `@` is empty.
- on push reject:
  - `origin`: refetch origin, `jj rebase -d main@origin`, push again once.
  - `rad`: stop and report — rad should not diverge from origin. do not force.
