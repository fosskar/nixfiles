{ lib, ... }:
{
  # everything llm-related lives in this tree: the home-manager agent tooling
  # (pi, omp, codex, ...), skills, and extensions. skills are shared data with
  # several consumers — home-manager installs all of them into agent dirs,
  # nixos services (hermes) pick single ones — so the registry names them and
  # consumers reference self.llm.skills.<name> instead of reaching by path.
  flake.llm.skills = lib.mapAttrs (name: _: ./skills + "/${name}") (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./skills)
  );

  flake.llm.souls.tars = ./souls/TARS.md;
}
