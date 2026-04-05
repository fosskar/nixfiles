---
description: publish local commits to remote with jj
---

publish committed work. move `main` to latest non-empty commit. push only `main`.

rules:

- do not include uncommitted file changes in publish.
- fetch first, always.
- rebase local stack onto latest `main` before moving bookmark.
- keep it simple.

flow:

1. inspect
   - `jj status`
   - `jj log -r 'main | main@origin | @ | @-' -n 20`
2. fetch remote
   - `jj git fetch`
3. rebase current stack onto updated main
   - `jj rebase -d main`
4. move local main to latest non-empty local commit
   - `jj bookmark set main -r @-`
5. push only main
   - `jj git push --bookmark main`
6. verify
   - `jj status`
   - `jj log -r 'main | main@origin | @ | @-' -n 20`

guardrails:

- never set `main` to `@` when `@` is empty.
- no `jj restore`, `git restore`, `git checkout --`.
- if push rejects, run: fetch -> rebase -d main -> push again.
