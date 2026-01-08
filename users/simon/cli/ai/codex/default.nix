{ pkgs, inputs, ... }:
{
  programs.codex = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
  };
}
