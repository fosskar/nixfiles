# UI Prototype

Generate **several radically different variants** of a page or component, flip between them in the browser, pick one (or steal bits from each), then throw the rest away.

If the question is about logic/state rather than what something looks like — wrong branch. Use [LOGIC.md](LOGIC.md).

## When this is the right shape

- "What should this page look like?"
- "I want to see a few options for this layout before committing."
- Any time the user would otherwise spend a day picking between three vague mockups in their head.

## Process

### 1. State the question and pick N

Default to **3 variants**. More than 5 stops being radically different and starts being noise. Write the plan in one line at the top of the prototype file.

### 2. Generate radically different variants

Hold each variant to:

- The page's purpose and the data it has access to.
- The project's existing styling system — in an Astro site with hand-written CSS, that means hand-written CSS and the existing layout/CSS variables; don't import a framework for a prototype.

Variants must be **structurally different** — different layout, different information hierarchy, different primary affordance, not just different colours. If two drafts come out too similar, redo one with explicit "do not use the same structure" guidance.

### 3. Wire them together

Prefer mounting the variants **inside the real page** they'd live on, so they're judged against real content and density — a variant in a vacuum always looks fine. Only create a standalone scratch page when there's genuinely no host page.

In a static-site setup (Astro): one scratch page (or the host page, temporarily) renders all variants, switchable by a `?variant=` URL param read in a small inline `<script>` that toggles visibility — no router needed. Add a fixed bottom-centre switcher pill (prev/next arrows + variant label, `←`/`→` keys) styled to be obviously not part of the design under evaluation.

Run the dev server the way the repo prescribes (e.g. `nix develop`, then the site's dev script) and hand over the local URL with the variant keys.

### 4. Capture the answer and clean up

The interesting feedback is usually "the header from B with the sidebar from C" — that's the actual design. Write down which variant won and why (commit message, decision record, or `NOTES.md`). Fold the winner into the real page; delete the losing variants, the switcher, and any scratch page. Prototype code was written under prototype constraints — rewrite it properly when folding it in.

## Anti-patterns

- **Variants that differ only in colour or copy.** That's a tweak, not a prototype. Real variants disagree about structure.
- **Sharing too much layout between variants.** Each variant should be free to throw out the layout.
- **Committing the prototype.** The scratch page and switcher never land in a commit; fold in the winner only.
