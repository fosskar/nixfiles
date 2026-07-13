# Wayfinding operations per forge

Detect the forge from the repo's remote URL (`git remote -v` / `jj git remote list`):

- `github.com` → GitHub, use `gh`
- Forgejo/Gitea hosts (including `codeberg.org`) → use `fj` (`berg` lacks assign/close/labels — don't use it for wayfinding)
- No forge remote → local-markdown fallback below

Labels (`wayfinder:map`, `wayfinder:research`, `wayfinder:prototype`, `wayfinder:grilling`, `wayfinder:task`) must exist in the repo before first use. On GitHub create them with `gh label create <name>`; on Forgejo create them in the web UI if missing, or fall back to a `[wayfinder:<type>]` title prefix.

## GitHub (`gh`)

Native sub-issues and dependencies — use them, no body conventions.

| Operation | Command |
| --- | --- |
| Create map | `gh issue create --label wayfinder:map --title <name> --body-file <f>` |
| Create ticket | `gh issue create --parent <map#> --label wayfinder:<type> --title <name> --body <q>` |
| Wire blocking (second pass) | `gh issue edit <n> --add-blocked-by <m>` (also `--add-blocking`, `--remove-blocked-by`) |
| Claim | `gh issue edit <n> --add-assignee @me` |
| Resolve | `gh issue comment <n> --body <answer>` then `gh issue close <n>` |
| Update map body | `gh issue edit <map#> --body-file <f>` |
| Open children | `gh api repos/{owner}/{repo}/issues/<map#>/sub_issues` and keep `state == "open"` (multi-label `gh issue list` filters AND labels — useless here, each ticket has one type label) |
| Frontier | from open children, keep unassigned ones with no open blocked-by; check relationships per issue (`gh issue view <n>`, else the dependency endpoints via `gh api`) — verify the query shape once on a real repo before relying on it |

## Forgejo / Gitea (`fj`)

CLI has no sub-issue or dependency commands — use body conventions; the map is the index of children.

| Operation | Command / convention |
| --- | --- |
| Create map | `fj issue create --body-file <f> "<name>"`, then add `wayfinder:map` via `fj issue edit <n> labels` |
| Create ticket | `fj issue create --body <q> "<name>"`; ticket body ends with `Map: #<map#>` |
| Wire blocking | line in ticket body: `Blocked by: #<m>` (one per blocker); edit via `fj issue edit <n> body`. Forgejo has native dependencies in the web UI — mirror there if a visual frontier is wanted |
| Claim | `fj issue assign <n> <user>` |
| Resolve | `fj issue comment <n> <answer>` then `fj issue close <n>` |
| Update map body | `fj issue edit <map#> body` |
| Open children / frontier | `fj issue search` for open issues referencing the map, or walk the map's ticket links; frontier = unassigned with every `Blocked by:` target closed (`fj issue view <m>`) |

Flag shapes above are from `fj --help` at time of writing — verify with `fj issue <cmd> --help` before first use in a session.

## Local-markdown fallback (no forge)

One file per effort: `wayfinder/<slug>.md` in the cwd (ask the human where if unclear). Map body sections as in SKILL.md, plus a `## Tickets` section holding the children inline:

```markdown
## Tickets

### <ticket name> `wayfinder:<type>` <!-- open|closed, claimed-by: <who>, blocked-by: <ticket name>, ... -->

#### Question

<the question>

#### Resolution

<empty until resolved; the answer lives here>
```

Frontier = open, unclaimed tickets whose every blocked-by is closed. Closing a ticket = mark closed, fill Resolution, append its one-liner to Decisions so far.
