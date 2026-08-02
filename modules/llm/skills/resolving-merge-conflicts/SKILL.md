---
name: resolving-merge-conflicts
description: "Use when you need to resolve an in-progress merge/rebase conflict, in jj or git."
---

First determine the VCS: a `.jj` directory means jj (even when `.git` is also present — colocated repos are driven through jj). Only fall back to raw git commands when there is no `.jj`.

1. **See the current state.**
   - jj: `jj status` lists conflicted files; `jj log` shows which commits carry conflicts (jj records conflicts _in_ commits — nothing is "stopped", descendants already exist and auto-rebase once the conflict is resolved). Read the conflict markers in the working copy.
   - git: `git status`, `git log --merge`, and the conflicting files.

2. **Find the primary sources** for each conflict. Understand deeply why each change was made, and what the original intent was. Read the commit messages on both sides (`jj log -r 'ancestors(@, 10)'` / `git log`), and check the associated PRs and issues via the `gh` CLI.

3. **Resolve each hunk.** Preserve both intents where possible. Where incompatible, pick the one matching the merge's stated goal and note the trade-off. Do **not** invent new behaviour. Always resolve; never abort — and in jj, never `jj abandon` or `jj restore`.

4. Discover the project's **automated checks** and run them — typically `nix fmt`, then the repo's test suite (`cargo test`, `go test ./...`, `npm test`), then `nix flake check` or building the touched machine's `toplevel` in config repos. Fix anything the merge broke.

5. **Finish.**
   - jj: editing the files _is_ the resolution — there is no staging and no `--continue`; once markers are gone the conflict is resolved and descendants rebase automatically. Verify with `jj status` (no remaining conflicts).
   - git: stage everything and commit; if rebasing, `git rebase --continue` until all commits are rebased.
   - Do not push; the user decides when to push.
