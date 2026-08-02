---
name: nixpkgs-pr-tracker
description: Track where a nixpkgs PR has landed. Given a PR number or URL, checks whether its merge commit reached staging-next, master, nixos-unstable-small, nixpkgs-unstable, nixos-unstable, and nixos-26.05.
---

Answer "has nixpkgs PR #N reached my channel yet?" by checking git ancestry of
the PR's merge commit against each tracked branch, like pr-tracker websites do.
Everything is GitHub REST API via `curl` + `jq` (unauthenticated works; set
`GITHUB_TOKEN` or use `gh api` instead of `curl` if rate-limited).

## 1. Parse the input

Reduce whatever the user dropped to a PR number:

- `https://github.com/NixOS/nixpkgs/pull/12345` → `12345`
- bare number → use as-is
- package name / commit sha only → find the PR first:
  `curl -s 'https://api.github.com/search/issues?q=repo:NixOS/nixpkgs+type:pr+<query>'`

## 2. Get the merge commit

```bash
curl -s https://api.github.com/repos/NixOS/nixpkgs/pulls/12345 \
  | jq -r '"\(.merged)\t\(.merge_commit_sha)\t\(.base.ref)\t\(.title)"'
```

- `merged` is `false` → report "not merged yet", note the base branch, stop.
- `base.ref` matters: PRs merge into `master`, `staging`, or `release-*` —
  propagation starts from there (see pipeline below).

## 3. Check each branch

A branch contains the PR when the compare status of `branch...merge_commit` is
`identical` or `behind` (merge commit is an ancestor of the branch head).
`ahead`/`diverged` → not landed there yet.

```bash
sha=<merge_commit_sha>
for branch in staging-next master nixos-unstable-small nixpkgs-unstable nixos-unstable nixos-26.05; do
  status=$(curl -s "https://api.github.com/repos/NixOS/nixpkgs/compare/$branch...$sha" | jq -r .status)
  case "$status" in
    identical|behind) echo "$branch: yes" ;;
    ahead|diverged)   echo "$branch: no" ;;
    *)                echo "$branch: unknown ($status)" ;;
  esac
done
```

## 4. Report

Present one line per branch (landed / not yet), then say where the PR sits in
the pipeline and what it is waiting for:

```
staging → staging-next → master ─┬─ nixos-unstable-small   (fast channel, fewer Hydra tests)
                                 ├─ nixpkgs-unstable        (packages-only channel)
                                 └─ nixos-unstable          (full Hydra tested channel)
release-26.05 ──────────────────── nixos-26.05              (stable channel)
```

- merged into `staging` → waits for the next staging-next cycle, then master
- in `master` but not in a channel branch → waiting on Hydra; small channel
  moves first, `nixos-unstable` last
- channel branches only ever advance to Hydra-tested master commits

## Caveats

- **Backports**: a stable branch never contains the original merge commit —
  backports are cherry-picks with new SHAs merged via a separate PR into
  `release-26.05`. If the user cares about `nixos-26.05`, find the backport PR
  (search `repo:NixOS/nixpkgs+type:pr+<original-PR-number> in:body`, or check
  the original PR's timeline for "backport" links) and track _that_ PR's merge
  commit against `nixos-26.05`.
- Stable branch names change each release; if `nixos-26.05` 404s, list current
  channel branches: `curl -s 'https://api.github.com/repos/NixOS/nixpkgs/branches?per_page=100' | jq -r '.[].name' | grep -E '^nixos-[0-9]'`.
- Unauthenticated API = 60 req/h. One full check is 7 requests; if rate-limited,
  authenticate (`gh api` with the same paths, or `curl -H "Authorization: Bearer $GITHUB_TOKEN"`).
