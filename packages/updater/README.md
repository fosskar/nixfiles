# updater

Updates third-party sources in this repository and opens one PR per unit,
with automerge. The forge — GitHub, or Codeberg/Forgejo — is detected from
the origin remote. Two entrypoints share one pipeline
(branch, push dedupe, PR create/refresh, automerge, green-race unstick):

| binary                 | unit                | branch                      | commit message         |
| ---------------------- | ------------------- | --------------------------- | ---------------------- |
| `updater-packages`     | `packages/<name>`   | `update-package-<group>`    | nix-update generated   |
| `updater-flake-inputs` | `flake.lock` inputs | `update-flake-input-<name>` | `flake: update <name>` |

## Usage

```bash
nix run .#updater -- --list                     # list updatable packages
nix run .#updater -- --dry-run -p limux         # update one package, no push
nix shell .#updater -c updater-flake-inputs --list
nix shell .#updater -c updater-flake-inputs --dry-run -i nixpkgs
```

Without `--dry-run` a forge token is required: `FORGE_TOKEN` (or
`CODEBERG_TOKEN`); on a GitHub-hosted repo this is a GitHub token.
`GITHUB_TOKEN` is optional but avoids GitHub API rate limits (nix-update
version lookups, release-note enrichment) — in production both are set from
the same nixbot secret.

Both tools refuse to run on a dirty working tree: they hard-reset and clean
the checkout per unit. Use a scratch clone, or commit first.

In production both run as nixbot scheduled effects
(`modules/flake-parts/effects.nix`), in a throwaway clone with the token
injected from nixbot's secrets.

## How packages are discovered

- `packages/<name>/package.nix` with `passthru.updateScript = nix-update-script { ... }`
  -> updated via nix-update with those args (probed via `nix eval`, so the
  attr may live in any file).
- executable `packages/<name>/update.sh` -> run directly (nix shebang).
- neither -> skipped, printed loudly.
- opt out explicitly with `passthru.updateScript = null` (this package does).

Packages sharing a name prefix (`netbird-*`) are grouped into one branch/PR
to keep the PR count down (originally because Codeberg's anti-spam rejected
bursts of similar PRs).

## Flake inputs

Discovers every `flake.nix` in the repo (skips those without a lock file)
and opens one PR per root input. Units are named `<input>` for the root
flake and `<dir>#<input>` for nested flakes; `--exclude` takes fnmatch
globs on unit names (repeatable, e.g. `--exclude 'templates/*#*'`).
`follows`-indirections are skipped (nothing to update). GitHub inputs get
a `Diff:` compare URL in the commit message, which the changelog
enrichment expands into release notes in the PR body.

## PR lifecycle

- branch is recreated from `origin/main` each run; tree + commit-message
  comparison against the remote branch skips no-op force-pushes (and CI
  reruns)
- existing PR gets title/body refreshed instead of a duplicate
- automerge (squash) is scheduled via API: Forgejo
  `merge_when_checks_succeed` (deletes the branch on merge), GitHub GraphQL
  `enablePullRequestAutoMerge` (needs the repo settings "allow auto-merge"
  and "automatically delete head branches"); if checks went green _before_
  automerge was scheduled it never fires - the next run detects the stuck
  PR and merges it directly (`merge_if_green`)
- on Codeberg `merge_if_green` trusts branch protection: the direct merge
  405s while the required status is pending. On GitHub it verifies CI
  itself - branch protection is unavailable on private free-plan repos, so
  it merges (pinned to the verified head sha) only when the
  `nixbot/nix-build` check run on the PR head concluded successfully; a
  missing run fails closed
- rate-limited (429) forge calls are retried with backoff; a unit that is
  still throttled is deferred, not failed - the next run pushes nothing
  (tree unchanged) and creates the missing PR

## Files

| file                     | role                                          |
| ------------------------ | --------------------------------------------- |
| `update_packages.py`     | entrypoint: packages/                         |
| `update_flake_inputs.py` | entrypoint: flake.lock inputs                 |
| `pipeline.py`            | shared: token, dirty guard, push/PR/automerge |
| `packages.py`            | package discovery + nix-update/update.sh runs |
| `forge.py`               | forge REST clients (GitHub, Codeberg/Forgejo) |
| `changelog.py`           | release-note enrichment, stale-URL fix        |
| `test_updater.py`        | pure-logic tests, run in checkPhase           |

## Tests

```bash
cd packages/updater && python3 -m unittest test_updater -v
```

Also run automatically at build time (`checkPhase`).
