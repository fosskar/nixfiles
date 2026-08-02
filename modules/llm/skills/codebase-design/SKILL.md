---
name: codebase-design
description: Shared vocabulary for designing deep modules. Use when the user wants to design or improve a module's interface, find deepening opportunities, decide where a seam goes, make code more testable or AI-navigable, or when another skill needs the deep-module vocabulary.
---

# Codebase Design

Design **deep modules**: a lot of behaviour behind a small interface, placed at a clean seam, testable through that interface. Use this language and these principles wherever code is being designed or restructured. The aim is leverage for callers, locality for maintainers, and testability for everyone.

## Glossary

Use these terms exactly — don't substitute "component," "service," "API," or "boundary." Consistent language is the whole point.

**Module** — anything with an interface and an implementation. Deliberately scale-agnostic: a function, class, package, or tier-spanning slice. _Avoid_: unit, component, service.

**Interface** — everything a caller must know to use the module correctly: the type signature, but also invariants, ordering constraints, error modes, required configuration, and performance characteristics. _Avoid_: API, signature (too narrow — they refer only to the type-level surface).

**Implementation** — what's inside a module, its body of code. Distinct from **Adapter**: a thing can be a small adapter with a large implementation (a Postgres repo) or a large adapter with a small implementation (an in-memory fake). Reach for "adapter" when the seam is the topic; "implementation" otherwise.

**Depth** — leverage at the interface: the amount of behaviour a caller (or test) can exercise per unit of interface they have to learn. A module is **deep** when a large amount of behaviour sits behind a small interface, **shallow** when the interface is nearly as complex as the implementation.

**Seam** _(Michael Feathers)_ — a place where you can alter behaviour without editing in that place; the _location_ at which a module's interface lives. Where to put the seam is its own design decision, distinct from what goes behind it. _Avoid_: boundary (overloaded with DDD's bounded context).

**Adapter** — a concrete thing that satisfies an interface at a seam. Describes _role_ (what slot it fills), not substance (what's inside).

**Leverage** — what callers get from depth: more capability per unit of interface they learn. One implementation pays back across N call sites and M tests.

**Locality** — what maintainers get from depth: change, bugs, knowledge, and verification concentrate in one place rather than spreading across callers. Fix once, fixed everywhere.

## Deep vs shallow

**Deep module** = small interface + lots of implementation:

```
┌─────────────────────┐
│   Small Interface   │  ← Few methods, simple params
├─────────────────────┤
│                     │
│  Deep Implementation│  ← Complex logic hidden
│                     │
└─────────────────────┘
```

**Shallow module** = large interface + little implementation (avoid):

```
┌─────────────────────────────────┐
│       Large Interface           │  ← Many methods, complex params
├─────────────────────────────────┤
│  Thin Implementation            │  ← Just passes through
└─────────────────────────────────┘
```

When designing an interface, ask:

- Can I reduce the number of methods?
- Can I simplify the parameters?
- Can I hide more complexity inside?

## Principles

- **Depth is a property of the interface, not the implementation.** A deep module can be internally composed of small, mockable, swappable parts — they just aren't part of the interface. A module can have **internal seams** (private to its implementation, used by its own tests) as well as the **external seam** at its interface.
- **The deletion test.** Imagine deleting the module. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it was earning its keep.
- **The interface is the test surface.** Callers and tests cross the same seam. If you want to test _past_ the interface, the module is probably the wrong shape.
- **One adapter means a hypothetical seam. Two adapters means a real one.** Don't introduce a seam unless something actually varies across it.

## Designing for testability

Good interfaces make testing natural:

1. **Accept dependencies, don't create them.**

   ```rust
   // Testable: any gateway impl works, tests pass a fake
   fn process_order(order: Order, gateway: &impl PaymentGateway) { ... }

   // Hard to test: constructs its own dependency internally
   fn process_order(order: Order) {
       let gateway = StripeGateway::from_env();
   }
   ```

2. **Return results, don't produce side effects.**

   ```go
   // Testable: pure input → output, assert on the return value
   func CalculateDiscount(cart Cart) Discount { ... }

   // Hard to test: mutates its argument, nothing to assert on directly
   func ApplyDiscount(cart *Cart) { cart.Total -= discount }
   ```

3. **Small surface area.** Fewer methods = fewer tests needed. Fewer params = simpler test setup.

## Relationships

- A **Module** has exactly one **Interface** (the surface it presents to callers and tests).
- **Depth** is a property of a **Module**, measured against its **Interface**.
- A **Seam** is where a **Module**'s **Interface** lives.
- An **Adapter** sits at a **Seam** and satisfies the **Interface**.
- **Depth** produces **Leverage** for callers and **Locality** for maintainers.

## In Nix config repos

The vocabulary maps onto the flake-parts aspect-module model (see the repo's `AGENTS.md` for the full model). Use the repo's terms for the things, this glossary's terms for the properties:

- **Module** — an aspect or feature module (`flake.modules.nixos.<name>`, `flake.modules.homeManager.<name>`).
- **Interface** — everything an importer must know: with import = enable, the ideal interface is _the import line itself_. Every `enable` flag, option, or required companion setting widens it.
- **Seam** — the composition edge: a machine's `configuration.nix` imports, or a clan role/tag assignment in `machines/flake-module.nix`.
- **Adapter** — a clan service role, or the per-context wiring of a multi-context aspect (nixos side vs home-manager side).
- **Deep aspect** — one import yields the whole feature: service + homepage tile + gatus endpoint + reverse proxy + persistence + secrets (feature-owned integration). That is the repo's stated ideal.
- **Shallow aspect** — a module that sets one or two options its single importer could set directly. Candidate for inlining — but see the caveats.
- **Leverage** — one aspect imported by N machines; **locality** — all glue for a service lives in its feature module, not scattered across hosts.

Caveats that override the generic principles:

- **The deletion test never applies to unimported modules.** Zero importers ≠ dead code: exported-but-unimported aspects are a deliberate library of ready-to-enable features. Inventory, never deletion candidates.
- **Duplication beats indirection here.** Per-module hand-written homepage/gatus/caddy stanzas are preferred over registry/helper options, even at significant LOC cost (decided and recorded). Only propose helper extraction when it deletes net lines or has a concrete second consumer in reach.
- **Prefer upstream namespaces** (`services.*`, `programs.*`, `preservation.*`) over new options — hardcode sane defaults before adding configurability.

## Rejected framings

- **Depth as ratio of implementation-lines to interface-lines** (Ousterhout): rewards padding the implementation. We use depth-as-leverage instead.
- **"Interface" as the TypeScript `interface` keyword or a class's public methods**: too narrow — interface here includes every fact a caller must know.
- **"Boundary"**: overloaded with DDD's bounded context. Say **seam** or **interface**.

## Going deeper

- **Deepening a cluster given its dependencies** — see [DEEPENING.md](DEEPENING.md): dependency categories, seam discipline, and replace-don't-layer testing.
- **Exploring alternative interfaces** — see [DESIGN-IT-TWICE.md](DESIGN-IT-TWICE.md): spin up parallel sub-agents to design the interface several radically different ways, then compare on depth, locality, and seam placement.
