{ pkgs, inputs, ... }:
{
  programs.codex = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
    settings = {
      approval_policy = "never";
      sandbox_mode = "danger-full-access";
      tui.status_line = [
        "model-with-reasoning"
        "current-dir"
        "project-root"
        "git-branch"
        "context-remaining"
      ];
    };
  };
}
