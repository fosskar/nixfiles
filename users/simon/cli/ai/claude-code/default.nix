{
  mylib,
  pkgs,
  inputs,
  ...
}:
{
  imports = mylib.scanPaths ./. { };

  home.file.".claude/CLAUDE.md" = {
    source = ../AGENTS.md;
  };

  home.packages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.ccstatusline
    pkgs.gh
  ];

  programs = {
    claude-code = {
      enable = true;
      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;

      enableMcpIntegration = true;

      settings = {
        theme = "dark";
        verbose = true;
        includeCoAuthoredBy = false;
        autoUpdates = false;
        enableAllProjectMcpServers = true;
        teammateMode = "tmux";
        env = {
          CLAUDE_CODE_ENABLE_TELEMETRY = "0";
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
          DISABLE_ERROR_REPORTING = "1";
          DISABLE_TELEMETRY = "1";
          DISABLE_AUTOUPDATER = "1";
          CLAUDE_CODE_IDE_SKIP_AUTO_INSTALL = "1";
          CLAUDE_CODE_AUTO_CONNECT_IDE = "0";
          DISABLE_NON_ESSENTIAL_MODEL_CALLS = "1";
          CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        };
        statusLine = {
          type = "command";
          padding = 0;
          command = "ccstatusline";
        };
      };
    };
  };
}
