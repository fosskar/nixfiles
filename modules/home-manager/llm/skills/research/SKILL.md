---
name: research
description: Investigate a question against high-trust primary sources and capture the findings as a cited Markdown note. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork delegated to a background agent.
---

Spin up a **background agent** to do the research, so you keep working while it reads.

Its job:

1. Investigate the question against **primary sources** — official docs, source code, specs, first-party APIs — not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Write the findings to a single Markdown file, citing each claim's source.
3. Route the file by scope:
   - **Repo-specific findings** (this codebase's dependency, API, design question) → the repo's own docs convention (`docs/`, or wherever it already keeps such notes).
   - **General, reusable knowledge** (a technology, protocol, tool — useful beyond this repo) → a note in the wiki repo (`~/Projects/wiki`): `wiki/<section>/<slug>.md`, following its `AGENTS.md` conventions (frontmatter, note type `guide`/`troubleshooting`/`reference`, unique slug). Research becomes permanent bliki content instead of a one-off scratch file.
   - Unsure which — ask, or default to the repo and say so.
