---
name: nixbot-check
description: Triage nixbot CI with the `nbo` CLI. Drop a PR URL, a nixbot build URL, or a failed pipeline and it finds the build, classifies each failed attribute, and drives the fix loop — reproduce locally, fix, watch. Also for watching build status, restarting builds, or fetching full logs.
---

nixbot instance: `https://nixbot.fosskar.eu`. Drive it with `nbo` (package
`nixbot-cli`, in the nixfiles devshell and on the nixbot host). `NIXBOT_URL` is
preset in both; elsewhere export it. Reads are anonymous; restart/cancel/enable
need `NIXBOT_TOKEN` (create at `/settings`).

Exit codes are stable, so scripts can branch on them: `0` ok, `1` build or
attribute failed, `2` usage/not found, `4` auth.

## 1. Point nbo at the build

Inside a checkout the repository comes from the `origin` remote and the build
from `HEAD`, so most triage is a bare command. Otherwise:

| input                                                  | selector                               |
| ------------------------------------------------------ | -------------------------------------- |
| current checkout, current commit                       | nothing — `nbo log`                    |
| GitHub PR `github.com/<owner>/<repo>/pull/<N>`         | `--pr <N>`                             |
| Codeberg PR `codeberg.org/<owner>/<repo>/pulls/<N>`    | `--pr <N> -R gitea/<owner>/<repo>`     |
| commit sha                                             | `--commit <sha-prefix>`                |
| nixbot URL `…/repos/{forge}/{owner}/{name}/builds/{n}` | build number `n`, `-R {forge}/{o}/{n}` |
| another repo, no checkout                              | `-R github/fosskar/nixfiles`           |

```bash
nbo repo list                       # enabled repos, when unsure of the id
nbo build list --pr 247             # newest first; also --branch --commit --status
nbo build view 492                  # status, attribute summary, failed attributes
```

`--json [fields]` on `build list`/`build view`/`log` prints machine-readable
output, optionally projected: `nbo build list --json number,status,branch`.

## 2. Get the failures

```bash
nbo log                             # why HEAD's build failed: errors + log tails
nbo log 492                         # same for one build
nbo log 492 nixos-nixbox --tail 200 # one attribute, substring match is enough
nbo log 492 nixos-nixbox --follow   # stream while it still builds
nbo log 492 /nix/store/…-foo.drv    # one derivation of the attribute
```

`nbo log` exits 1 when the build failed. A build-level `error` instead of
per-attribute failures means evaluation itself failed — nothing was built, fix
that first. `eval_warnings` show up in `--json`.

## 3. Classify each failed attribute → what to do

| attr status         | meaning                              | action                                                                                                            |
| ------------------- | ------------------------------------ | ----------------------------------------------------------------------------------------------------------------- |
| `failed_eval`       | attribute didn't evaluate            | reproduce with `nix flake check --no-build` or `nix eval` on the attr; fix the eval error at source               |
| `failed`            | real build failure                   | read the log tail first — the error is usually in the last lines; then reproduce locally: `nix build .#<attr> -L` |
| `dependency_failed` | cascade noise                        | ignore; find the root `failed` attr and fix only that                                                             |
| `cached_failure`    | failure cached from an earlier build | the error names the build that first failed; debug there, fix, then `nbo build restart`                           |
| `skipped_local`     | not built on this instance           | informational, not a failure                                                                                      |

Map the attr to its source:

- `nixos-<machine>` → that machine's config; reproduce with `nix build .#nixosConfigurations.<machine>.config.system.build.toplevel`
- `package-<name>` → `packages/<name>/package.nix`
- `devshell-<name>` → `modules/flake-parts/shells/`

## 4. Fix loop

1. Reproduce locally with the command from the table — never guess from the log
   alone when a local repro is one command away.
2. Fix at source; prove with the same local command going green.
3. The user pushes (never push for them); then watch:

```bash
nbo build watch                                  # HEAD's build, exit 1 on failure
nbo build watch 493 --attr nixos-nixbox --attr treefmt   # wait only for these
```

On a terminal `watch` shows finished attributes above a live view of the running
ones; piped it prints one line per finished attribute.

If the failure isn't obvious from log + local repro, switch to the
diagnosing-bugs skill — the local repro command is already your Phase 1 feedback
loop.

## 5. Control (needs `NIXBOT_TOKEN`, otherwise exit 4)

```bash
nbo build restart 492                # everything
nbo build restart 492 --attr treefmt # one attribute, after fixing a cached_failure
nbo build restart 492 --effects      # re-run the effects only
nbo build cancel 492
nbo repo enable github/fosskar/wiki  # admin
```

## Effects

Repos also run **effects** — hercules-ci effects from `flake.herculesCI`
(`modules/flake-parts/effects.nix`: `renovate`, `update-pkgs`,
`update-flake-inputs`). Neither `nbo` nor the JSON API covers effect runs; use
the web routes:

```bash
# scheduled runs of one effect (HTML)
curl -s 'https://nixbot.fosskar.eu/repos/github/fosskar/nixfiles/schedules/runs?schedule=update-pkgs&effect=update-pkgs'
# plain-text log of one run
curl -s https://nixbot.fosskar.eu/repos/github/fosskar/nixfiles/schedules/runs/209.txt
```

Local repro with `nbo effects` (nixfiles devshell; also takes remote flakerefs,
no checkout needed):

```bash
nbo effects list-schedules [flakeref]
nbo effects run-scheduled [flakeref#]<schedule> <effect>
```

`nbo effects list` / `graph` / `run` cover `onPush` effects, which this repo has
none of; their names are job-prefixed (`default.<effect>`).

Two caveats for this repo's repo-mutating effects:

- they set `checkout = true` (nixbot's `mkEffect`), so a local run needs
  `--effect-checkout <path-to-a-clone>` or it aborts; the effect runs _in_ that
  clone, not in your working tree
- in CI they get the GitToken secret injected and push. Locally pass
  `--secrets`/a scratch clone only when you mean it, and prefer the updater's
  `--dry-run`

## Raw API leftovers

Everything else is `curl` + `jq` (`/llms.txt`, `/api/openapi.json`):

```bash
# per-attribute history across builds (flaky? regressed at which commit?)
curl -s https://nixbot.fosskar.eu/api/repos/github/fosskar/nixfiles/attrs/<attr>
# global queue
curl -s https://nixbot.fosskar.eu/api/queue
```
