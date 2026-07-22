---
name: architecture-review
description: Scan a codebase for architecture problems, explain practical improvements in a visual HTML report, then explore whichever one you pick.
disable-model-invocation: true
---

# Architecture Review

Surface architectural friction and propose **deepening opportunities** — refactors that turn shallow modules into deep ones. The aim is testability and AI-navigability. Explain findings for a technical reader who does not already know architecture vocabulary.

This command is _informed_ by the project's domain model and built on a shared design vocabulary:

- Run the codebase-design skill for the architecture vocabulary (**module**, **interface**, **depth**, **seam**, **adapter**, **leverage**, **locality**) and its principles (the deletion test, "the interface is the test surface", "one adapter = hypothetical seam, two = real"). Use that vocabulary to reason accurately, but translate it into ordinary language in the report. State what the code does and why it is awkward before naming the architectural concept. Never make the reader decode jargon to understand a recommendation.
- The project's own terminology lives in `AGENTS.md` and module/option names — use it. Decision records (`docs/decisions/`, `docs/DECISIONS.md`, or similar) record decisions this command should not re-litigate.

## Process

### 1. Explore

Read `AGENTS.md` and any decision records in the area you're touching first.

Then use sub-agents to walk the codebase. Don't follow rigid heuristics — explore organically and note where you experience friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow** — interface nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, but the real bugs hide in how they're called (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts of the codebase are untested, or hard to test through their current interface?

Apply the **deletion test** to anything you suspect is shallow: would deleting it concentrate complexity, or just move it? A "yes, concentrates" is the signal you want.

**Nix repos:** apply the "In Nix config repos" mapping and caveats from the codebase-design skill — in particular: unimported modules are library inventory, never deletion candidates.

### 2. Present candidates as an HTML report

Write a self-contained HTML file to the OS temp directory so nothing lands in the repo. Resolve the temp dir from `$TMPDIR`, falling back to `/tmp`, and write to `<tmpdir>/architecture-review-<timestamp>.html` so each run gets a fresh file. Open it for the user with `xdg-open <path>` and tell them the absolute path.

The report is **dark mode**, uses **Tailwind via CDN** for layout and styling, and **Mermaid via CDN** for diagrams where a graph/flow/sequence reliably communicates the structure. Mix Mermaid with hand-crafted CSS/SVG visuals — use Mermaid when relationships are graph-shaped (call graphs, dependencies, sequences), and hand-built divs/SVG when you want something more editorial (mass diagrams, cross-sections, collapse animations). Each candidate gets a **before/after visualisation**. Be visual.

For each candidate, render a card with:

- **Files** — which files/modules are involved
- **What happens today** — concrete call/configuration flow, using project names
- **Why this hurts** — the observable cost: scattered changes, hidden coupling, weak tests, or repeated knowledge
- **What would change** — plain English description of the new responsibility and where it would live
- **Why this is better** — concrete effects on changes and tests; introduce terms such as locality or leverage only in parentheses after the plain explanation
- **Before / After diagram** — side-by-side, labelled with concrete actions rather than abstract jargon
- **Recommendation strength** — one of `Strong`, `Worth exploring`, `Speculative`, rendered as a badge

Write as if explaining the finding to a maintainer seeing this area for the first time. Prefer a small example over a definition. Expand acronyms on first use. Keep sentences short, but include enough context to answer: what calls what, what knowledge is duplicated or exposed, and what becomes easier after the change.

End the report with a **Top recommendation** section: which candidate you'd tackle first and why.

**Use the project's own terminology for the domain.** If the repo calls something an "aspect module," talk about "the gaming aspect module" — not "the GamingConfigHandler," and not "the gaming service." Use codebase-design terms only after the underlying idea is clear in ordinary language.

**Decision-record conflicts**: if a candidate contradicts an existing decision record, only surface it when the friction is real enough to warrant revisiting the decision. Mark it clearly in the card (e.g. a warning callout: _"contradicts docs/decisions/state-persistence.md — but worth reopening because…"_). Don't list every theoretical refactor a recorded decision forbids.

See [HTML-REPORT.md](HTML-REPORT.md) for the full HTML scaffold, diagram patterns, and styling guidance.

Do NOT propose interfaces yet. After the file is written, ask the user: "Which of these would you like to explore?"

### 3. Grilling loop

Once the user picks a candidate, run the grilling skill to walk the design tree with them — constraints, dependencies, the shape of the deepened module, what sits behind the seam, what tests survive.

Side effects happen inline as decisions crystallize:

- **Naming a deepened module after a concept the repo's terminology doesn't cover?** Add the term where the repo keeps its vocabulary (`AGENTS.md` or docs).
- **User rejects the candidate with a load-bearing reason?** Offer a decision record, framed as: _"Want me to record this so future architecture reviews don't re-suggest it?"_ Only offer when the reason would actually be needed by a future explorer to avoid re-suggesting the same thing — skip ephemeral reasons ("not worth it right now") and self-evident ones.
- **Want to explore alternative interfaces for the deepened module?** Run the codebase-design skill and use its design-it-twice parallel sub-agent pattern.
