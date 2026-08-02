---
name: agents-md
description: Create or update a repo's AGENTS.md. Use when the user wants an AGENTS.md bootstrapped for a bare repo, or an existing one updated, refreshed, or checked for stale claims.
---

# AGENTS.md

Pick the branch by one test: does `AGENTS.md` exist at the repo root?

- **No** → [Bootstrap](#bootstrap): generate one from the codebase.
- **Yes** → [Audit](#audit): verify and patch it. Regenerating an existing file is never an option — hand-maintained rules and recorded decisions cannot be rediscovered from code.

## Bootstrap

Launch multiple `explore` agents in parallel scanning different areas (core src, tests, configs/build, scripts/docs), then synthesize findings into one file at the repo root.

Sections, as applicable: project overview · architecture & data flow · key directories · development commands (build, test, lint, run) · code conventions & patterns · important files · runtime/tooling preferences · testing & QA.

Directives:

- Concise and practical; written for an AI assistant working in the repo.
- Concrete examples where they help: commands, paths, naming patterns.
- Call out architecture and code patterns explicitly.
- Omit what is obvious from code structure.
- Match the register of the user's other AGENTS.md files (terse, lowercase headings, no filler).

## Audit

The existing file is the **authority**; the repo is the evidence. The job is verification, not authorship.

1. **Inventory every claim.** Split the file into checkable claims (commands, paths, option names, counts, "no X exists" statements) and **decisions** (rules, preferences, rejections, style mandates). Decisions are not checkable against code — they are the user's law and survive the audit untouched unless the user says otherwise.
2. **Verify each claim** against the repo — run the command, check the path, eval the option. Launch `explore` agents in parallel for independent areas. Classify: **true** (keep), **stale** (fix to match reality), **dead** (refers to something removed — flag, don't silently delete).
3. **Note gaps**: load-bearing facts an assistant needs that the file lacks (new subsystems, changed commands). Propose additions in the file's own register and structure — never impose a template, never retitle.
4. **Patch surgically.** Edit only lines with a verified defect or an accepted gap. Title, structure, ordering, register stay. Rejections and "do not re-suggest" records are sacred: they exist _because_ code cannot express them — removing one is never a fix.
5. **Report the diff** grouped as fixed / added / flagged-dead, each with its evidence. The user decides on flagged items.

Done when every claim in the file is classified true/stale/dead with evidence, every stale claim is patched, and the diff contains no removed or reworded decision.
