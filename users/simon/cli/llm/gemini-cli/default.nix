{ pkgs, inputs, ... }:
{
  programs.gemini-cli = {
    enable = false;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.gemini-cli;
  };
}
