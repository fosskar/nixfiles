{ pkgs, inputs, ... }:
{
  programs.gemini-cli = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.system}.gemini-cli;
  };
}
