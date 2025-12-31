# AGENTS.md

In all interactions and commit messages, be extremely concise and sacrifice on grammar for the sake of concision.

## ai guidance

- stop when stuck, avoid sycophantic language
- parallelize independent operations
- verify solutions before finishing
- do what's asked - nothing more, nothing less
- prefer editing existing files over creating new ones
- never create docs/readme files unless explicitly requested
- when testing/debugging, comment out code instead of deleting it

## vcs

- **prefer jj over git** (colocated repos)
- **atomic commits always** - one logical change per commit. never bundle unrelated changes. no exceptions
- **lowercase everything** (text, comments, commits) except product names (NixOS, GitHub, etc.)
- **newline at end of files**

## plans

- at the end of each plan, give me a list of unresolved questions to answer, if any. make the questions extremely concise. sacrifice grammar for the sake of concision

## nix

- prefer flake-native commands (`nix build`, `nix shell`, `nix develop`) over legacy (`nix-build`, `nix-shell`)
- use `nix shell nixpkgs#<pkg>` to temporarily get missing tools
- `nix fmt` - format nix files
- always check **unstable** channel for modules/packages
- new files must be `jj file track` (or `git add`) for nix flake

## devops

- everything as code, declarative over imperative
- immutable infrastructure, reproducible environments
