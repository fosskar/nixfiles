# CLAUDE.md

## ai guidance

- MUST follow CLAUDE.md guidance, conventions, instructions etc.
- stop when stuck
- AVOID sycophantic language
- after receiving tool results, carefully reflect on their quality and determine optimal next steps before proceeding. use your thinking to plan and iterate based on this new information, and then take the best next action
- for maximum efficiency, whenever you need to perform multiple independent operations, invoke all relevant tools simultaneously rather than sequentially.
- before you finish, please verify your solution
- do what has been asked; nothing more, nothing less.
- NEVER create files unless they're absolutely necessary for achieving your goal.
- ALWAYS prefer editing an existing file to creating a new one.
- NEVER proactively create documentation files (\*.md) or README files. Only create documentation files if explicitly requested by the user.

## coding style and conventions

### text formatting

- never use capital letters except for company or product names (NixOS, GitHub, Claude, etc.)
- all text should be lowercase including comments, documentation, and responses
- commit messages must be lowercase
- use atomic commits - each commit should represent one logical change or concern (git and jj)
- always add a newline at the end of files (essential for proper file formatting)

### file formatting by type

- **nix files**: nixfmt-rfc-style formatting (2-space indentation, aligned attributes)
- **yaml/yml**: 2-space indentation, no trailing spaces
- **json**: 2-space indentation, proper nested structure
- **shell scripts**: 2-space indentation, proper quoting
- **markdown**: consistent heading styles, proper list formatting
- **helm charts**: yaml formatting with 2-space indentation, proper template syntax, consistent values.yaml structure
- **go**: gofmt standard formatting (tabs for indentation, proper imports grouping, no trailing spaces)

## technology stack

### desktop environment

- **compositor**: hyprland (wayland) with quickshell/hyprpanel bars
- **launcher**: anyrun and sherlock
- **terminals**: ghostty, wezterm with fish shell and starship prompt
- **editors**: zed, neovim, vscodium

### core tools and patterns

- **package management**: nix flakes for reproducible builds and development environments
- **system management**: `nh` wrapper for better nixos-rebuild/home-manager experience
- **secrets management**: agenix (age encryption) and sops-nix
- **documentation**: primarily markdown with some typst for formatted documents

## development workflows

### nix ecosystem

- `nix develop` - enter development shell
- `nix flake check` - validate flake configuration
- `nix flake update` - update all inputs
- `nix build` - build packages/systems
- `direnv allow` - enable automatic dev shell activation

### nixos system management

- `nh os switch` - rebuild and switch nixos system configuration (preferred method)
- `nh home switch` - rebuild and switch home manager configuration
- `nixos-rebuild switch --flake .` - alternative system rebuild method

### code quality (nix projects)

- `nixfmt-rfc-style` - format nix files (runs automatically via pre-commit)
- `deadnix` - find unused nix code
- `statix` - static analysis for nix code
- `nil` - nix language server for diagnostics

### version control

- **prefer jj over git** when available for better workflow and conflict resolution
- `jj status` - see working copy changes (no staging area)
- `jj diff` - view changes with better diff tools
- `jj describe -m "message"` - add commit message to current change
- `jj new` - create new change (like git commit)
- `jj log` - view commit history with bookmarks
- `jj bookmark track main@origin` - track remote bookmarks
- use colocated mode (`jj git init --colocate`) for git compatibility

## devops principles

### core philosophy

- **everything as code**: infrastructure, configurations, policies, and documentation should be version controlled
- **version control as single source of truth**: all changes flow through git/jj repositories with proper review processes
- **declarative over imperative**: describe desired state, not manual steps to achieve it
- **immutable infrastructure**: replace rather than modify running systems
- **reproducible environments**: development, staging, and production should be consistent

### nix-specific practices

- avoid manual configuration changes - codify everything in nix
- prefer nix expressions and modules over shell scripts for system configuration
- prevent drift by ensuring all system state is defined in version control
- validate changes before applying them (nix flake check, build tests)

### automation and quality

- automate repetitive tasks wherever possible
- use pre-commit hooks and ci/cd to enforce quality standards
- implement automated testing and validation
- maintain disaster recovery procedures

### kubernetes and container orchestration

- `kubectl apply -f` - apply kubernetes manifests
- `helm template` - render helm charts
- `argocd app sync` - sync applications
- use kubectl with context switching for multi-cluster management
- prefer helm charts for application deployments
- use gitops patterns with argocd/kargo for deployment automation
- container images should be built reproducibly with proper tagging

### observability and security

- implement proper logging with structured formats and meaningful metrics
- set up alerts for critical system components with documented runbooks
- follow least privilege principles for service accounts
- use secrets management tools (sops, agenix) rather than plain text
- regularly update dependencies and base images
- implement proper network policies and rbac
- use gradual rollouts with canary deployments and feature flags
