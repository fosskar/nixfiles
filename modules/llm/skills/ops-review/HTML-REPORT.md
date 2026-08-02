# HTML Report Format

The ops review is rendered as a single self-contained HTML file in the OS temp directory. **Dark mode throughout** — dark backgrounds, light text, colours picked for contrast on dark. Tailwind and Mermaid both come from CDNs. Mermaid handles the graph-shaped diagrams (blast radius, exposure paths); hand-built divs and inline SVG handle the editorial visuals (state-boundary cross-sections, coverage matrices). Mix the two — don't lean on Mermaid for everything.

## Scaffold

```html
<!doctype html>
<html lang="en" class="dark">
  <head>
    <meta charset="utf-8" />
    <title>Ops review — {{repo name}}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script type="module">
      import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
      mermaid.initialize({
        startOnLoad: true,
        theme: "dark",
        themeVariables: {
          darkMode: true,
          background: "#0f172a",
          primaryColor: "#1e293b",
          primaryTextColor: "#e2e8f0",
          primaryBorderColor: "#475569",
          lineColor: "#64748b",
        },
        securityLevel: "loose",
      });
    </script>
    <style>
      /* small custom layer:
         drift edges dashed, SPOFs red-ringed, coverage gaps hatched */
      .drift {
        stroke-dasharray: 4 4;
      }
      .spof {
        border: 2px solid #f87171;
      }
      .gap {
        background: repeating-linear-gradient(
          45deg,
          #450a0a,
          #450a0a 4px,
          #1e293b 4px,
          #1e293b 8px
        );
      }
    </style>
  </head>
  <body class="bg-slate-950 text-slate-200 font-sans">
    <main class="max-w-5xl mx-auto px-6 py-12 space-y-12">
      <header>...</header>
      <section id="findings" class="space-y-10">...</section>
      <section id="top-risk">...</section>
    </main>
  </body>
</html>
```

## Header

Repo name, date, and a compact legend: box = service, cluster = host (failure domain), red ring = SPOF, dashed line = drift, hatched cell = coverage gap. No introduction paragraph — straight into the findings.

## Finding card

The diagrams carry the weight. Prose is sparse, plain, and uses the vocabulary terms (from `SKILL.md`) without ceremony.

Each finding is one `<article>` — dark card: `rounded-lg border border-slate-800 bg-slate-900`:

- **Title** — short, names the risk (e.g. "Gateway death takes the mesh with it"). `text-slate-100`.
- **Badge row** — severity (`Critical` = red-400 on red-950, `Worth hardening` = amber-400 on amber-950, `Accepted risk` = slate-400 on slate-800), plus a tag for the lens (`blast radius`, `state boundary`, `probe coverage`, `exposure`, `secrets`, `update risk`).
- **Failure domain** — monospaced list of hosts/services, `font-mono text-sm text-slate-400`.
- **Diagram** — the centrepiece. See patterns below.
- **Finding** — one sentence. What breaks, and how you'd find out.
- **Mitigation** — one sentence. What changes.
- **Wins** — bullets, ≤6 words each, in vocabulary terms: _"blast radius: DNS survives gateway death"_, _"restore path: repo + backup, no UI step"_, _"probe: alert beats the user report"_.
- **Decision-record callout** (if applicable) — one line in an amber-tinted box (`border-amber-700 bg-amber-950 text-amber-200`).

No paragraphs of explanation. If the diagram needs a paragraph to be understood, redraw the diagram.

## Diagram patterns

Pick the pattern that fits the finding. Mix them — variety is part of the point.

### Blast-radius graph (the workhorse)

Mermaid `flowchart` with a `subgraph` per host, arrows = runtime dependency. Colour the failing domain and everything downstream of it red; the surviving remainder stays dim. Before/after pairs work well: same graph, radius visibly smaller after the mitigation.

```html
<div class="rounded-lg border border-slate-800 bg-slate-900 p-4">
  <pre class="mermaid">
    flowchart LR
      subgraph gateway
        NB[netbird-server]
        PROXY[netbird-proxy]
      end
      subgraph nixbox
        IMMICH[immich]
      end
      IMMICH -->|mesh auth| NB
      classDef dead fill:#450a0a,stroke:#f87171;
      class NB,PROXY,IMMICH dead
  </pre>
</div>
```

### Exposure path

Mermaid `flowchart LR` tracing one request: internet → ingress → peer:port, LAN → vhost → localhost:port. Dashed `.drift` edge for any hop configured outside the repo. The point is the hop count and who owns each hop.

### State-boundary cross-section (hand-built)

Columns = rungs (ephemeral / persisted / backed up / offsite), rows = services. Each cell a small div; the rung the state actually reaches is filled, everything to the right is empty — a `.gap` hatched cell marks where the finding lives. Reads like a coverage heatmap; no arrows needed.

### Probe-coverage matrix

Plain table, services × (probe, alert route). Covered = dim check, uncovered = `.gap` cell. Good when the finding is "N services dark", where a graph would just be noise.

### Restore-path ladder

Numbered vertical steps from bare metal to running service. Steps the repo covers get solid borders; steps that live in a UI or in memory get dashed `.drift` borders and a red step number. Before/after: the after ladder has no dashed steps.

## Style guidance

- Lean editorial, not corporate-dashboard. Generous whitespace. Serif optional for headings (`font-serif` reads well in slate on dark).
- Dark palette: `slate-950` page, `slate-900` cards, `slate-800` borders, `slate-200` body text, `slate-100` headings, `slate-400`/`slate-500` for secondary and dimmed.
- Colour sparingly: one accent (emerald-400 or indigo-400) plus red-400 for dead/uncovered and amber-400 for warnings — the 400-range keeps contrast on dark backgrounds.
- Keep diagrams ~320px tall so before/after sits comfortably side by side without scrolling.
- Use `text-xs uppercase tracking-wider` for service labels inside diagrams — schematic, not UI.
- The only scripts are the Tailwind CDN and the Mermaid ESM import. The report is otherwise static.

## Top risk section

One larger card. Finding name, one sentence on why it goes first, anchor link to its card. That's it.

## Tone

Plain English, concise — but the operational nouns come straight from the skill's vocabulary. Concision is not an excuse to drift.

**Use exactly:** failure domain, blast radius, SPOF, state boundary, restore path, probe, exposure surface, drift.

**Never substitute:** outage, incident (for a failure domain dying) · disaster recovery, DR (for restore path) · observability, monitoring gap (for probe coverage) · attack surface (for exposure surface) · snowflake, manual config (for drift).

**Phrasings that fit the style:**

- "Gateway is a SPOF — mesh coordination and public ingress share its failure domain."
- "State sits one rung low: persisted, never backed up."
- "Restore path dead-ends at a UI step."
- "Probe added: the alert beats the user report."

No hedging, no throat-clearing, no "it's worth noting that…". If a sentence could be a bullet, make it a bullet. If a bullet could be cut, cut it. If a term isn't in the vocabulary, reach for one that is before inventing a new one.
