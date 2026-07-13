---
name: wayfinder
description: Chart a way through a pathless problem — one with no known solution, not even a theoretical one — as a map of decision tickets on the repo's issue tracker. Pure exploration and planning; never builds.
disable-model-invocation: true
---

A pathless problem has arrived: not merely big, but **directionless** — no candidate solution exists yet, not even a theoretical one. Wayfinding is about finding the way, never walking it. This skill first finds a **direction**, then charts the way toward it as a **shared map** of **decision tickets** on the repo's issue tracker, and resolves them one at a time until the route to the **destination** is clear.

## Explore, never build

Every ticket resolves a decision; the map is done when nothing is left to decide before someone goes and does the thing. The pull to just do the work is the signal you've reached the edge of the map — hand off instead.

**No solution code, ever.** The only code this skill may touch is a disposable prototype (see [Ticket types](#ticket-types)) — evidence for a decision, abandoned once the question is answered. If a resolution seems to require writing real code, the ticket is mis-typed: it's either a prototype (throwaway) or it belongs past the destination, in the handoff.

## Find the direction first

Charting needs a destination, and a pathless problem doesn't have one yet. Before any map exists, **diverge, then converge**:

1. **Diverge.** Survey the option space: fire `/research` subagents at prior art — how others solved adjacent problems, what the ecosystem offers, what constraints are real. Generate **2–4 candidate directions**, each with its tradeoffs stated plainly.
2. **Converge.** Put the candidates to the human via `/grilling` — one question at a time, your recommendation marked. The human picks the direction; you never pick it for them.
3. The chosen direction fixes the **destination** — what reaching the end of this map looks like: a spec to hand off, a decision locked, a plan someone can execute. Every ticket is charted toward it.

If the problem arrives with a direction already obvious, say so and skip straight to charting — but pathless problems rarely do; assume this phase is needed until shown otherwise.

**When the diverge phase is itself heavy** — several research subagents, more than one grilling round — don't hold it in your head where a dying session loses it. Create the map _first_ with destination `(finding direction)`, and make **Choose direction** its first grilling ticket, blocked by the prior-art research tickets. The direction question _is_ the first decision; once it resolves, rewrite the map's Destination and chart from there. Light cases keep the inline flow above.

## The Map

The map is a single issue on this repo's issue tracker, labelled `wayfinder:map` — the canonical artifact. Its tickets are child issues of the map. How map, children, blocking, and frontier queries are physically expressed depends on the forge — see [FORGES.md](FORGES.md). No forge remote at all → the local-markdown fallback there.

The map is an **index**, not a store. It lists the decisions made and points at the tickets that hold their detail; a decision lives in exactly one place — its ticket — so the map never restates it, only gists it and links.

### The map body

The whole map at low resolution, loaded once per session. Open tickets are **not** listed — they are open child issues, found by query.

```markdown
## Destination

<the chosen direction and what reaching the end of this map looks like. One or two lines; every session orients to it before choosing a ticket.>

## Directions considered

<!-- from the diverge phase: one line per rejected candidate — gist plus why not -->

## Notes

<domain; skills every session should consult; standing preferences for this effort>

## Decisions so far

<!-- the index — one line per closed ticket: enough to judge relevance, then zoom the link -->

- [<closed ticket title>](link) — <one-line gist of the answer>

## Not yet specified

<!-- see "Fog of war": in-scope fog you can't ticket yet -->

## Out of scope

<!-- work ruled beyond the destination; closed, never graduates -->
```

### Tickets

Each ticket is a **child issue** of the map; its body is one question, sized to one agent session:

```markdown
## Question

<the decision or investigation this ticket resolves>
```

Each carries a `wayfinder:<type>` label — `research`, `prototype`, `grilling`, or `task`.

A session **claims** a ticket by assigning it to the dev driving the map, **first**, before any work — the assignee _is_ the claim; open and unassigned means unclaimed. A ticket is **unblocked** when every ticket blocking it is closed; the **frontier** is the open, unblocked, unclaimed children — the edge of the known.

The answer isn't part of the body — it's recorded on resolution. Assets created while resolving are linked from the issue, never pasted in.

## Ticket types

Every ticket is **HITL** — worked _with_ the human, who speaks for themselves — or **AFK**, driven by the agent alone. A HITL ticket only resolves through that live exchange; the agent never answers for the human (a grilling that answers its own questions has broken this).

- **Research** (AFK): surface a fact a decision waits on — docs, source, prior art. Resolved by a `/research` subagent. Findings land as a resolution comment with citations.
- **Prototype** (HITL): raise the fidelity of the discussion with a cheap, disposable artifact to react to — an outline, a diagram, a stub, or throwaway code via `/prototype`. The artifact is evidence, linked from the ticket and abandoned; it never graduates into the solution.
- **Grilling** (HITL): conversation via `/grilling`, one question at a time. The default type.
- **Task** (HITL or AFK): real-world prep a _decision_ is blocked on — signing up for a service, provisioning access, moving data so its shape can be seen. The one type that _does_ rather than decides, and it earns its place by unblocking a decision, never by delivering the destination. Agent drives it alone where it can; otherwise it hands the human a precise checklist. The answer records what was done and any resulting facts later tickets depend on.

## Fog of war

The map is _deliberately_ incomplete: don't chart what you can't yet see. Beyond the live tickets lies the **fog of war** — decisions you can tell are coming but can't pin down yet. Resolving a ticket clears the fog ahead of it, graduating whatever's now specifiable into fresh tickets, until the way to the destination is clear and no tickets remain.

**Not yet specified** on the map holds that dim view: the suspected question, the area to revisit. Everything there is in scope, just not sharp enough to ticket. **Fog or ticket?** The test is whether you can state the question precisely _now_ — not whether you can answer it now. Sharp question → ticket, even if blocked. Fuzzy → fog; don't pre-slice it into ticket-sized pieces.

**Out of scope** is different: work consciously ruled beyond the destination. It never graduates — the frontier stops at the destination. When an existing ticket turns out to sit past the destination, **close it** and leave one line in Out of scope: gist, why, link. It stays out of Decisions so far, which records only the route actually walked.

## Refer by name

Every map and ticket has a **name** — its title. In everything the human reads, refer to it by that name with the link riding inside it, never by a bare number. A wall of `#42, #43, #44` is illegible.

## Invocation

Two modes. Either way, **never resolve more than one ticket per session** — research tickets excepted.

### Chart the map

Invoked with a pathless problem.

1. **Find the direction** (see above): diverge, converge, destination named.
2. **Map the frontier.** Grill breadth-first — fan out across the whole space, surfacing the open decisions and the first steps takeable now. If this surfaces no fog — the route already clear, small enough for one session — no map is needed; stop and hand the human the plan directly.
3. **Create the map** (label `wayfinder:map`): Destination, Directions considered, and Notes filled in; Decisions-so-far empty; fog sketched into Not yet specified.
4. **Create the tickets you can specify now** as children, then wire blocking edges in a **second pass** (issues need ids before they can reference each other).
5. **Fire the research subagents** — one `/research` per research ticket, in parallel; each reports back as a resolution comment on its ticket.
6. Stop — charting is one session's work; it hand-resolves nothing.

### Work through the map

Invoked with a map (URL or number); a ticket is optional — without one, you pick.

1. Load the **map** — the low-res view, not every ticket body.
2. Choose the ticket: the one named, else the first frontier ticket. **Claim it** before any work.
3. Resolve it — zoom into related or closed tickets on demand; invoke the skills the map's Notes name. In doubt, `/grilling`.
4. Record the resolution: answer as a **resolution comment**, **close** the issue, append one line to the map's Decisions so far.
5. Tend the map: create-then-wire newly surfaced tickets; graduate fog the answer sharpened, clearing each graduated patch from Not yet specified; rule mis-scoped tickets out of scope; update or delete tickets the decision invalidated.

6. **Finish the map** when the frontier is empty and no fog remains: post a **handoff comment** on the map — the way itself, an ordered plan linking each decision that shaped it — then close the map issue. A closed map means the way is found; walking it is a fresh effort, not this one.

Other sessions may be working the tracker concurrently — expect it.
