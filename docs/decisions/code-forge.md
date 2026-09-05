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

## codeberg's generative-ai policy (2026-07)

after the move, a second and independent reason against codeberg landed. two proposals were put to a codeberg e. V. member vote ending 2026-07-22; both passed. the second one (358 for, 144 against, 14 abstentions, ~50% turnout) added § 2 (1) 7 to the terms of use:

> you must not share projects that mostly consist of code written by "generative AI"-tools (including services such as *Claude*, *OpenAI Codex*).

the stated grounds are unclear copyright status (§ 2 (1) 1 and 3) and missing safeguards against harmful code (§ 2 (1) 5). enforcement under § 2 (2) is content removal plus a warning, then account suspension on repeat.

the announcement (`blog.codeberg.org/protecting-our-floss-commons-from-llms.html`) names cases that "might no longer be welcome", and this repo sits on three of them:

- projects created by LLM "agents" in autonomous ways
- projects written and maintained with heavy use of LLMs
- projects heavily tied to the LLM ecosystem, e.g. LLM-written tools to ease LLM usage

nixfiles is maintained agent-first (`AGENTS.md`, per-machine and per-module agent playbooks), and `modules/llm/` is exactly "LLM-written tools to ease LLM usage": agent tooling, skills, souls, pi-pack wiring. the mitigating cases codeberg lists — significant pre-LLM history, an active human community — cover part of the repo but not `modules/llm/`.

the rule is enforced by human judgement and trust, not scanning: codeberg maintainers state there is no detection tooling and no sweep, and that obvious cases combined with high resource usage get moderated first (`codeberg.org/Codeberg/Community/issues/2933`). that cuts both ways. nothing is likely to happen tomorrow, but hosting now depends on a moderator's reading of "mostly" for a repo whose working method is explicitly disfavoured, with removal and account suspension as the escalation path.

this is not a complaint about the policy. codeberg's reasoning (crawler load, hardware costs, license laundering, review burden, erosion of collaboration) is coherent and follows from its mission. the conclusion is that the mission and this repo's working method no longer fit: the platform does not want the kind of work done here, and continuing to push it there is neither honest nor sustainable.

consequence: codeberg is out as a primary forge candidate for as long as this rule stands, independently of the automation friction above. the mirror stays for now — pre-LLM history, low resource usage, no CI — but it is a courtesy copy on a platform that has said what it thinks of the workflow, not a fallback that can be promoted.

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
- codeberg fixes bot friction *and* the generative-ai rule is withdrawn or narrowed; either alone is not enough
