---
name: nixbot-check
description: Triage nixbot CI. Drop a PR URL, a nixbot build URL, or a failed pipeline and it finds the build, classifies each failed attribute, and drives the fix loop — reproduce locally, fix, watch. Also for watching build status or fetching full logs.
---

nixbot instance: `https://nixbot.fosskar.eu` (JSON API under `/api`, no auth
needed for reads; OpenAPI at `/api/openapi.json`, summary at `/llms.txt`).
There is no nixbot CLI — everything is `curl` + `jq`.

## 1. Parse the input

Whatever the user dropped, reduce it to `{forge}/{owner}/{name}` + a build:

- Codeberg PR `codeberg.org/<owner>/<repo>/pulls/<N>` → repo `gitea/<owner>/<repo>`, filter `pr_number=<N>`
- GitHub PR `github.com/<owner>/<repo>/pull/<N>` → repo `github/<owner>/<repo>`, filter `pr_number=<N>`
- nixbot web URL `nixbot.fosskar.eu/repos/{forge}/{owner}/{name}/builds/{number}` → direct
- bare build number or branch → filter `builds?branch=` / use the number; repo from context (cwd's repo) or ask

Discover repos when unsure:

```bash
curl -s https://nixbot.fosskar.eu/api/repos | jq -r '.[] | "\(.forge)/\(.owner)/\(.name)"'
```

Find the build (newest first; other filters: `commit` sha-prefix, `status`, `page`):

```bash
curl -s 'https://nixbot.fosskar.eu/api/repos/gitea/fosskar/nixfiles/builds?pr_number=42' \
  | jq -r '.items[] | "\(.number)\t\(.status)\t\(.branch)\t\(.commit_sha[:10])"'
```

## 2. Get the failures

```bash
curl -s 'https://nixbot.fosskar.eu/api/repos/gitea/fosskar/nixfiles/builds/123/failures?tail=80' \
  | jq -r '.error // empty, (.failures[] | "== \(.attr) (\(.status)) ==\n\(.error // "")\n\(.log_tail // "")")'
```

Returns `{status, error, eval_warnings, failures: [{attr, status, error, log_tail}]}`.
A top-level `error` means evaluation itself failed — nothing was built; fix that first.

## 3. Classify each failed attribute → what to do

| attr status         | meaning                              | action                                                                                                                 |
| ------------------- | ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| `failed_eval`       | attribute didn't evaluate            | reproduce with `nix flake check --no-build` or `nix eval` on the attr; fix the eval error at source                    |
| `failed`            | real build failure                   | read the `log_tail` first — the error is usually in the last 80 lines; then reproduce locally: `nix build .#<attr> -L` |
| `dependency_failed` | cascade noise                        | ignore; find the root `failed` attr and fix only that                                                                  |
| `cached_failure`    | failure cached from an earlier build | fix the root cause, then restart the build (see control) — nothing to debug in _this_ build                            |
| `skipped_local`     | not built on this instance           | informational, not a failure                                                                                           |

Map the attr to its source:

- `nixosConfigurations.<machine>…toplevel` → that machine's config; reproduce with `nix build .#nixosConfigurations.<machine>.config.system.build.toplevel`
- package attrs → `packages/<name>/package.nix`
- other `checks` attrs (VM tests, formatting, devshells) → the flake's `checks` wiring

Need more than the tail? Full plain-text log (note: no `/api` prefix):

```bash
curl -s 'https://nixbot.fosskar.eu/repos/gitea/fosskar/nixfiles/builds/123/logs/raw/<attr>?tail=500'
```

## 4. Fix loop

1. Reproduce locally with the command from the table — never guess from the log alone when a local repro is one command away.
2. Fix at source; prove with the same local command going green.
3. The user pushes (never push for them); then watch the new build:

```bash
while :; do
  s=$(curl -s https://nixbot.fosskar.eu/api/repos/gitea/fosskar/nixfiles/builds/124 | jq -r .build.status)
  echo "$s"; case "$s" in succeeded|failed|cancelled) break;; esac; sleep 30
done
```

If the failure isn't obvious from log + local repro, switch to the diagnosing-bugs skill — the local repro command is already your Phase 1 feedback loop.

## Other endpoints

```bash
# build + all attributes (statuses: pending|building|succeeded|failed|cancelled|skipped_local|dependency_failed|cached_failure|failed_eval)
curl -s https://nixbot.fosskar.eu/api/repos/gitea/fosskar/nixfiles/builds/123 \
  | jq -r '.attributes[] | "\(.attr)\t\(.status)"'

# per-attribute history across builds (flaky? regressed at which commit?)
curl -s https://nixbot.fosskar.eu/api/repos/gitea/fosskar/nixfiles/attrs/<attr>

# global queue
curl -s https://nixbot.fosskar.eu/api/queue
```

## Effects

Repos also run **effects** — hercules-ci effects defined in the flake (`flake.effects`). When an effect failed rather than a build attr, reproduce it locally with the `nixbot-effects` CLI (in the nixfiles devshell; also accepts remote flakerefs, no checkout needed):

```bash
nixbot-effects list [flakeref]               # available effects
nixbot-effects list-schedules [flakeref]     # scheduled effects
nixbot-effects run .#<effect>                # run one locally
nixbot-effects run-scheduled .#<schedule> <effect>
```

Caveat: effects in CI get secrets (e.g. the GitToken app secret) injected; a local run may lack them — pass `--secrets` / token files as needed, and never let a local effect run push anywhere the CI run would.

## Control (needs `Authorization: Bearer <token>`, created at /settings)

- `POST /api/repos/{forge}/{owner}/{name}/builds/{number}/restart` — after fixing a `cached_failure` root cause
- `POST .../cancel`
