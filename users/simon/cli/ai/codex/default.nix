{
  pkgs,
  inputs,
  ...
}:
{
  programs.codex = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
    enableMcpIntegration = true;

    settings = {
      model = "gpt-5.3-codex";
      model_reasoning_effort = "medium";

      approval_policy = "never";
      sandbox_mode = "workspace-write";
      sandbox_workspace_write = {
        network_access = true;
        exclude_tmpdir_env_var = false;
        exclude_slash_tmp = false;
      };
      tui = {
        notifications = true;
        animations = true;
        status_line = [
          "model-with-reasoning"
          "current-dir"
          "project-root"
          "git-branch"
          "context-remaining"
        ];
      };

      check_for_update_on_startup = false;
      feedback.enabled = false;
      project_doc_fallback_filenames = [ "CLAUDE.md" ];

      features = {
        shell_snapshot = true;
      };

      project_root_markers = [
        ".git"
        ".jj"
      ];
    };
  };
}
