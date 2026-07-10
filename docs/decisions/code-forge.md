# github over codeberg

this repo (and the other updater-driven repos) moved primary hosting back from codeberg to github on 2026-07-07 (`treewide: move nixfiles from codeberg to github`). codeberg remains as a mirror.

scope: primary code hosting and the PR/automerge pipeline around it (nixbot, `packages/updater`). the codeberg account and mirror are not part of what was given up.

## context

the original move to codeberg was values-driven: a non-profit FOSS forge, EU hosting, and interest in the forgejo ecosystem. those reasons still hold as values — the switch back is not a retraction of them.

## why switch back

automation friction, alone, forced the move. the update pipeline (one PR per unit, automerge, nightly schedule) fought the codeberg instance constantly; the scar tissue is still in the code:

- undocumented rate-limit windows, 429s without `Retry-After` — geometric backoff up to 185s cumulative (`packages/updater/forge.py`)
- merge endpoint throttled hard (observed `Retry-After` up to 120s), so automerge scheduling regularly lost the race against fast CI, leaving PRs scheduled forever — the `merge_if_green` sweep exists to unstick them (`packages/updater/pipeline.py`)
- anti-spam rejected bursts of similar PRs — package grouping (`netbird-*` into one PR) was built as a workaround (`packages/updater/update_packages.py`)

these are properties of the codeberg instance (shared infrastructure, protected by necessity), not of forgejo the software. every workaround shipped and worked; the friction still dominated day-to-day operation of the bot.

secondary: github app integration gives nixbot a first-class bot identity and commit attribution.

## rejected alternatives

- **self-hosted forgejo** — would remove the rate limits and keep independence, but: bootstrap circularity (nixfiles must stay reachable exactly when the infrastructure it defines is broken), one more always-on service to patch and back up, and a single VPS cannot match the availability bar CI and flake consumers assume.
- **adapting the tooling harder** — grouping, geometric backoff, deferred units, and the green-race sweep all shipped (see above). insufficient.
- **gitlab** — trades one corporate platform for a heavier one; same lock-in, worse ops. CI config tried and archived (`.archive/`).
- **sourcehut** — email-patch workflow does not fit a bot-driven PR + automerge pipeline.
- **tangled** — tracked as a flake input and genuinely interesting, but too immature to carry primary repos; no automerge-grade API. CI config tried and archived (`.archive/`).

## accepted tradeoffs

- values regression: primary hosting is back on a corporate platform the codeberg move deliberately left.
- data/jurisdiction sovereignty given up for the primary copy; the mirror keeps a copy elsewhere but is not the canonical repo.

## consequences

forge neutrality is a commitment, not residue: `packages/updater/forge.py` keeps both clients (github, codeberg/forgejo), and the pipeline derives the forge from the origin remote URL. switching forges again is a remote-URL change plus token swap, not a rewrite. the codeberg mirror stays warm for the same reason.

## revisit when

- github turns on policy or pricing that restricts API automation, or imposes terms not worth accepting
- tangled (or a comparable independent forge) matures to automerge-grade API and reliability
- codeberg fixes bot friction: documented rate limits, bot accounts, automerge that fires on already-green checks
