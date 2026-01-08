{ pkgs, inputs, ... }:
{
  programs.gemini-cli = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.gemini-cli;
  };
}
