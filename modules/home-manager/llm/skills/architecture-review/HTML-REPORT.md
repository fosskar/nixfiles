# HTML Report Format

The architectural review is rendered as a single self-contained HTML file in the OS temp directory. **Dark mode throughout** — dark backgrounds, light text, colours picked for contrast on dark. Tailwind and Mermaid both come from CDNs. Mermaid handles graph-shaped diagrams reliably; hand-built divs and inline SVG handle the more editorial visuals (mass diagrams, cross-sections). Mix the two — don't lean on Mermaid for everything, it'll start to look generic.

## Scaffold

```html
<!doctype html>
<html lang="en" class="dark">
  <head>
    <meta charset="utf-8" />
    <title>Architecture review — {{repo name}}</title>
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
      /* small custom layer for things Tailwind doesn't cover cleanly:
         dashed seam lines, hand-drawn-feeling arrow heads, etc. */
      .seam {
        stroke-dasharray: 4 4;
      }
      .leak {
        stroke: #f87171;
      }
      .deep {
        background: linear-gradient(135deg, #334155, #1e293b);
        border: 2px solid #94a3b8;
      }
    </style>
  </head>
  <body class="bg-slate-950 text-slate-200 font-sans">
    <main class="max-w-5xl mx-auto px-6 py-12 space-y-12">
      <header>...</header>
      <section id="candidates" class="space-y-10">...</section>
      <section id="top-recommendation">...</section>
    </main>
  </body>
</html>
```

## Header

Repo name, date, and a compact legend written in ordinary language: solid box = code/configuration grouped together, dashed line = where one module hands work to another, red arrow = internal knowledge leaking between modules, thick light-bordered box = one module hiding more complexity. Keep the legend visible so the diagrams do not require prior architecture knowledge.

## Candidate card

Use plain, concrete prose. Architecture terms may label a pattern after the report has explained what the code actually does.

Each candidate is one `<article>` — dark card: `rounded-lg border border-slate-800 bg-slate-900`:

- **Title** — short, names the practical result (e.g. "Keep the whole order check in one place"). `text-slate-100`.
- **Badge row** — recommendation strength (`Strong` = emerald-400 on emerald-950, `Worth exploring` = amber-400 on amber-950, `Speculative` = slate-400 on slate-800). Add a dependency-pattern tag only when it helps the reader, and spell out what the tag means in the card.
- **Files** — monospaced list, `font-mono text-sm text-slate-400`.
- **Before / After diagram** — two columns, side by side. Label nodes with project names and arrows with actions such as "reads", "calls", or "configures". See patterns below.
- **What happens today** — two or three short sentences describing the concrete flow.
- **Why this hurts** — name the maintenance or testing problem and give one representative example.
- **What would change** — say which responsibility moves where; do not lead with an abstract pattern name.
- **Why this is better** — short bullets connecting the change to easier edits or stronger tests. Add architecture vocabulary in parentheses only when useful, for example: "One file owns the rule (better locality)."
- **Decision-record callout** (if applicable) — one line in an amber-tinted box (`border-amber-700 bg-amber-950 text-amber-200`).

Diagrams support the explanation; they do not replace it. A reader should understand each candidate from the text alone, and understand each diagram without knowing the glossary.

## Diagram patterns

Pick the pattern that fits the candidate. Mix them. Don't make every diagram look the same — variety is part of the point.

### Mermaid graph (the workhorse for dependencies / call flow)

Use a Mermaid `flowchart` or `graph` when the point is "X calls Y calls Z, and look at the mess." Wrap it in a Tailwind-styled dark card so it doesn't feel parachuted in. Style with classDef to colour leakage edges red and the deep module light-bordered. Sequence diagrams work well for "before: 6 round-trips; after: 1."

```html
<div class="rounded-lg border border-slate-800 bg-slate-900 p-4">
  <pre class="mermaid">
    flowchart LR
      A[OrderHandler] --> B[OrderValidator]
      B --> C[OrderRepo]
      C -.leak.-> D[PricingClient]
      classDef leak stroke:#f87171,stroke-width:2px;
      class C,D leak
  </pre>
</div>
```

### Hand-built boxes-and-arrows (when Mermaid's layout fights you)

Modules as `<div>`s with borders and labels. Arrows as inline SVG `<line>` or `<path>` elements positioned absolutely over a relative container. Reach for this when you want the "after" diagram to feel like one thick-bordered deep module with dimmed internals — Mermaid won't render that with the right weight. On dark: deep module = `.deep` (light border, subtle gradient), dimmed internals = `text-slate-500 border-slate-700`.

### Cross-section (good for layered shallowness)

Stack horizontal bands (`h-12 border-l-4`) to show layers a call passes through. Before: 6 thin layers each doing nothing. After: 1 thick band labelled with the consolidated responsibility.

### Mass diagram (good for "interface as wide as implementation")

Two rectangles per module — one for interface surface area, one for implementation. Before: interface rectangle is nearly as tall as the implementation rectangle (shallow). After: interface rectangle is short, implementation rectangle is tall (deep).

### Call-graph collapse

Before: a tree of function calls rendered as nested boxes. After: the same tree collapsed into one box, with the now-internal calls shown faded inside it.

## Style guidance

- Lean editorial, not corporate-dashboard. Generous whitespace. Serif optional for headings (`font-serif` reads well in slate on dark).
- Dark palette: `slate-950` page, `slate-900` cards, `slate-800` borders, `slate-200` body text, `slate-100` headings, `slate-400`/`slate-500` for secondary and dimmed.
- Colour sparingly: one accent (emerald-400 or indigo-400) plus red-400 for leakage and amber-400 for warnings — the 400-range keeps contrast on dark backgrounds.
- Keep diagrams ~320px tall so before/after sits comfortably side by side without scrolling.
- Use `text-xs uppercase tracking-wider` for module labels inside diagrams — they should read as schematic, not as UI.
- The only scripts are the Tailwind CDN and the Mermaid ESM import. The report is otherwise static — no app code, no interactivity beyond Mermaid's own rendering.

## Top recommendation section

One larger card. Name the candidate, state the concrete problem it fixes, and explain why it should come first in two or three short sentences. Include an anchor link to its card.

## Tone

Write for a technical maintainer who knows the project but has not studied architecture terminology.

Follow this order:

1. Describe the current behavior using real files, modules, options, or calls.
2. Point out the concrete difficulty.
3. Describe the proposed change.
4. Explain what becomes easier.
5. Name the architecture concept only if it adds useful precision.

Prefer:

- "Changing order validation requires edits in four files because each file owns part of the rule."
- "Move the whole validation rule behind one `validateOrder` interface. Callers provide an order and receive errors."
- "Tests can now exercise the complete rule through one entry point. This improves locality: related behavior lives together."

Avoid:

- "The module lacks locality and leverage."
- "Deepen the seam through an adapter."
- "The interface surface approaches implementation mass."

When using **module**, **interface**, **implementation**, **depth**, **deep**, **shallow**, **seam**, **adapter**, **leverage**, or **locality**, explain the concrete meaning nearby. Do not replace accurate project terms with generic architecture terms.

No throat-clearing or filler. Concise does not mean cryptic: use short sentences, concrete examples, and enough context to understand the claim without opening every file.
