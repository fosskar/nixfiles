# AGENTS.md

## Build/Lint/Test Commands

- `nix flake check` - Run all checks including pre-commit hooks
- `nix fmt` - Format all Nix files with nixfmt-rfc-style
- `nix develop` - Enter dev shell with pre-commit hooks
- `nix build .#nixosConfigurations.desktop.config.system.build.toplevel` - Build system
- `nixos-rebuild dry-build --flake .#desktop` - Test system build
- `pre-commit run --all-files` - Run all pre-commit hooks manually
- `pre-commit run <hook-id> --files <file>` - Run specific hook on file (deadnix, nil, statix, prettier)

## Code Style Guidelines

- **Format**: Use `nixfmt-rfc-style` (enforced by pre-commit), `prettier` for non-Nix files
- **Linting**: `nil` (LSP), `deadnix` (unused code), `statix` (anti-patterns), `flake-checker`
- **Imports**: Use module imports with relative paths (e.g., `./browser`), inherit from inputs/outputs
- **Naming**: Use kebab-case for files/dirs, camelCase for options, inherit pattern for pkgs
- **Secrets**: Use `agenix` or `sops-nix` for sensitive data, detect-private-keys pre-commit hook
- **Structure**: Organize by host/service/function, modular home-manager configs under home/
- **Patterns**: Use `{ lib, pkgs, ... }:` for modules, `inherit` for cleaner code, `lib.mkIf` for conditionals
- **Error Handling**: Let Nix evaluation fail early, use assertions for critical checks
- **Documentation**: Comment complex logic, use descriptive option names, maintain README.md, capital letter in documentation and comments not allow
