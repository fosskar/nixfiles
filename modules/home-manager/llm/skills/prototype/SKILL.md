---
name: prototype
description: Build a throwaway prototype to answer a design question. Use when the user wants to sanity-check whether a state model or logic feels right, try out a NixOS module or service configuration without touching a real machine, or explore what a UI should look like.
---

# Prototype

A prototype is **throwaway code that answers a question**. The question decides the shape.

## Pick a branch

Identify which question is being answered — from the user's prompt, the surrounding code, or by asking if the user is around:

- **"Does this logic / state model feel right?"** → [LOGIC.md](LOGIC.md). Build a tiny interactive terminal app that pushes the state machine through cases that are hard to reason about on paper.
- **"Does this module / service / config shape actually work?"** → [OPS.md](OPS.md). Boot it in a throwaway NixOS VM and poke it — never experiment on a real machine.
- **"What should this look like?"** → [UI.md](UI.md). Render a few radically different variants and flip between them in the browser.

Getting the branch wrong wastes the whole prototype. If the question is genuinely ambiguous and the user isn't reachable, default to whichever branch better matches the surrounding code (a state-carrying module → logic; a nix module or service wiring → ops; a page or component → UI) and state the assumption at the top of the prototype.

## Rules that apply to all branches

1. **Throwaway from day one, and clearly marked as such.** Locate the prototype close to what it's prototyping for so context is obvious — but name it so a casual reader can see it's a prototype, not production.
2. **One command to run.** `cargo run --example <name>`, `go run ./cmd/<name>`, `python <path>`, `nix run`/`nix build` on a scratch attr — whatever the repo already supports. Throwaway tools come from `nix shell nixpkgs#<pkg>`, never a new package manager or global install.
3. **No persistence by default.** State lives in memory (or inside the VM, which is disposable). Persistence is the thing a prototype _checks_, not something it depends on.
4. **Skip the polish.** No tests, no error handling beyond what makes the prototype _runnable_, no abstractions. The point is to learn something fast and then delete it.
5. **Surface the state.** After every action, print or render the full relevant state so the user can see what changed.
6. **Delete or absorb when done.** When the prototype has answered its question, either delete it or fold the validated decision into the real code — don't leave it rotting in the repo.

## When done

The _answer_ is the only thing worth keeping from a prototype. Capture it somewhere durable (commit message, decision record, or a `NOTES.md` next to the prototype) along with the question it was answering. If the user is around, that capture is a quick conversation; if not, leave the placeholder so they (or you, on the next pass) can fill in the verdict before deleting the prototype.
