# AGENTS.md

## ai guidance

- stop when stuck, avoid sycophantic language
- parallelize independent operations
- verify solutions before finishing
- do what's asked - nothing more, nothing less
- prefer editing existing files over creating new ones
- never create docs/readme files unless explicitly requested
- when testing/debugging, comment out code instead of deleting it

## conventions

- **lowercase everything** (text, comments, commits) except product names (NixOS, GitHub, etc.)
- **atomic commits** - one logical change per commit
- **newline at end of files**

### linting & formatting

- **formatter** = fixes code style (indentation, spacing, etc.)
- **linter** = finds bugs, issues, bad practices
- nix: `nix fmt` (nixfmt-rfc-style)
- always use language-native tools (via `nix shell nixpkgs#<tool>` if not installed):
  - yaml: `yamlfmt` + `yamllint`
  - go: `gofmt`
  - json: `prettier` or `jq .`
  - shell: `shfmt` + `shellcheck`
  - etc.

## stack

- NixOS with flakes, `nh` wrapper for rebuilds
- secrets: sops-nix
- check existing configs to understand current setup before making changes

## workflows

### nix

- prefer flake-native commands (`nix build`, `nix shell`, `nix develop`) over legacy (`nix-build`, `nix-shell`)
- `nh os switch` / `nh home switch` - rebuild system/home
- `nix develop` / `direnv allow` - dev shells
- use `nix shell nixpkgs#<pkg>` to temporarily get missing tools
- `nix fmt` - format nix files (nixfmt-rfc-style)
- `deadnix`, `statix` - code quality
- always check **unstable** channel for modules/packages

### version control

- **prefer jj over git** (colocated mode for compatibility)
- `jj status`, `jj diff`, `jj describe -m "msg"`, `jj new`, `jj log`

## devops

- everything as code, declarative over imperative
- immutable infrastructure, reproducible environments
- gitops with argocd/kargo, helm for k8s deployments
- secrets via sops/agenix, least privilege, proper observability
