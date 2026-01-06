{ pkgs, inputs, ... }:
{
  programs.codex = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.system}.codex;
  };
}
