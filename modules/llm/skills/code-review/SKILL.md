---
name: code-review
description: Review the changes since a fixed point (commit, branch, tag, bookmark, or merge-base) against this repo's documented coding standards plus a fixed baseline of code smells. Use when the user wants to review a branch, a PR, work-in-progress changes, or asks to "review since X".
---

Standards review of the diff between the working copy and a fixed point the user supplies: does the code conform to this repo's documented coding standards, and does it avoid a fixed baseline of code smells?

## Process

### 1. Pin the fixed point

Whatever the user said is the fixed point — a commit SHA, branch, bookmark, tag, `main`, `HEAD~5`, etc. If they didn't specify one, ask for it.

Capture the diff once: `jj diff --from <fixed-point>` in jj repos, else `git diff <fixed-point>...HEAD` (three-dot, so the comparison is against the merge-base). Also note the commit list (`jj log -r '<fixed-point>..@'` or `git log <fixed-point>..HEAD --oneline`).

Before going further, confirm the fixed point resolves and the diff is non-empty. A bad ref or empty diff should fail here.

### 2. Identify the standards sources

Anything in the repo that documents how code should be written: `AGENTS.md`, `CONTRIBUTING.md`, `docs/DECISIONS.md`, or similar.

On top of whatever the repo documents, the review always carries the **smell baseline** below — a fixed set of Fowler code smells (_Refactoring_, ch.3) that applies even when a repo documents nothing. Two rules bind it:

- **The repo overrides.** A documented repo standard always wins; where it endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation — and, like any standard here, skip anything tooling already enforces.

Each smell reads _what it is_ → _how to fix_; match it against the diff:

- **Mysterious Name** — a function, variable, or type whose name doesn't reveal what it does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code** — the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy** — a method that reaches into another object's data more than its own. → move the method onto the data it envies.
- **Data Clumps** — the same few fields or params keep travelling together (a type wanting to be born). → bundle them into one type, pass that.
- **Primitive Obsession** — a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type.
- **Repeated Switches** — the same `switch`/`if`-cascade on the same type recurs across the change. → replace with polymorphism, or one map both sites share.
- **Shotgun Surgery** — one logical change forces scattered edits across many files in the diff. → gather what changes together into one module.
- **Divergent Change** — one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality** — abstraction, parameters, or hooks added for needs the task doesn't have. → delete it; inline back until a real need shows.
- **Message Chains** — long `a.b().c().d()` navigation the caller shouldn't depend on. → hide the walk behind one method on the first object.
- **Middle Man** — a class or function that mostly just delegates onward. → cut it, call the real target direct.
- **Refused Bequest** — a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.

For **`.nix` hunks** the Fowler baseline is largely mute; apply this nix baseline instead, under the same two binding rules:

- **Needless local abstraction** — single-use `let ... in`, a helper that only relocates boilerplate without deleting net lines or gaining a second consumer. → inline it; duplication beats indirection here.
- **`with` scoping** — `with pkgs;` and friends hide provenance. → explicit attribute paths.
- **Blunt override** — `lib.mkForce` without a demonstrated conflict. → `lib.mkDefault` for defaults; `mkForce` only where a real conflict exists.
- **Speculative option** — a new module option where a hardcoded sane default would do. → hardcode first; add the option when a second concrete need appears.
- **Needless enable-guard** — `mkIf config.services.<x>.enable` around contributions designed to be collected cross-host (dashboard tiles, monitoring endpoints). → contribute unconditionally; the collector filters.
- **Namespace invention** — a custom option tree where an upstream namespace (`services.*`, `programs.*`, `preservation.*`, `clan.core.*`) already models the thing. → use the upstream namespace.
- **Manual secret path** — a hardcoded secret file path where the repo's secret machinery (e.g. `clan.core.vars.generators`) is the convention. → wire through the generator.

### 3. Review

Walk the diff against the standards sources and the baseline. Report — per file/hunk where relevant:

- **(a)** every place the diff violates a documented standard: cite the standard (file + the rule);
- **(b)** any baseline smell you spot: name it and quote the hunk.

Distinguish hard violations from judgement calls — documented-standard breaches can be hard, but baseline smells are always judgement calls, and a documented repo standard overrides the baseline. Skip anything tooling enforces.

For a large diff, run the review in a sub-agent so the walk doesn't pollute the main context; paste the smell baseline into its prompt in full — the sub-agent has no other access to it.

### 4. Report

Findings grouped by file, hard violations before judgement calls. End with a one-line summary: total findings and the worst issue (if any).
