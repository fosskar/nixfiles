# Ops Prototype

A throwaway NixOS VM that answers "does this module / service / config shape actually behave?" — the kind of question where `nix eval` proves the value but only a booted system proves the behavior: does the service start, do the units order correctly, does the reverse proxy route, does the firewall rule bite.

Never answer these questions on a real machine. No deploys, no `nixos-rebuild switch`, no restarting services on remote hosts.

## When this is the right shape

- "Will this service wiring actually come up?"
- "Do these two modules conflict at runtime, not just at eval?"
- "What does this option really do to the generated unit / config file?"
- "Does the firewall/DNS/proxy behave the way I think?"

If the question is about a computed value only — wrong branch; a `nix eval` assertion answers it in seconds. If it's about program logic — [LOGIC.md](LOGIC.md).

## Process

### 1. State the question

One paragraph at the top of the scratch config: what shape is being tested, and what observable behavior decides the answer.

### 2. Build the smallest system that carries the question

Two options, cheapest first:

- **VM of an existing machine** — when the question is "what would this change do to `<machine>`": add the change, then `nix build .#nixosConfigurations.<machine>.config.system.build.vm` and run the resulting `result/bin/run-<machine>-vm`. Beware: the VM shares the machine's config but not its hardware/secrets; services needing real secrets may need stubs.
- **Scratch NixOS test** — when the question is about a module in isolation or an interaction between machines: write a throwaway NixOS test (`pkgs.testers.runNixOSTest` or the flake's existing checks pattern) with the minimal config importing just the module(s) under question. Run it interactively with the test driver (`--interactive`) to poke around, or script the assertion directly in `testScript` — then the prototype _is_ one red/green command.

### 3. Poke it

Inside the VM: `systemctl status`, `journalctl -u`, `curl` against the service, inspect generated files under `/etc`. Drive the exact behavior the question names — not a general smoke test.

### 4. Capture the answer and clean up

The validated config shape flows into the real module; the scratch test either gets deleted or — if the question was worth asking, it's often worth keeping red/green — promoted into the flake's `checks`. Delete the VM artifacts (`result`, disk images); they're large.

## Anti-patterns

- **Testing on a real host "just quickly".** The whole point of the branch is that VMs are free and machines are not.
- **A scratch config that grows options "while we're here".** One question per prototype.
- **Keeping the VM around as a pet.** Disposable means disposable — the keepable artifact is the config shape or the promoted check, never the image.
