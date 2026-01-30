{
  config,
  mylib,
  pkgs,
  inputs,
  ...
}:
{
  imports = mylib.scanPaths ./. { };

  home.file.".claude/claude-code-status.sh" = {
    source = ./claude-code-status.sh;
    executable = true;
  };

  home.file.".claude/CLAUDE.md" = {
    source = ../AGENTS.md;
  };

  home.packages = [
    inputs.llm-agents.packages.${pkgs.system}.ccstatusline
  ];

  programs = {
    claude-code = {
      enable = true;
      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
      settings = {
        theme = "dark";
        includeCoAuthoredBy = false;
        autoUpdates = false;
        enableAllProjectMcpServers = true;
        alwaysThinkingEnabled = true;
        env = {
          CLAUDE_CODE_ENABLE_TELEMETRY = "0";
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
          DISABLE_ERROR_REPORTING = "1";
          DISABLE_TELEMETRY = "1";
          DISABLE_AUTOUPDATER = "1";
          CLAUDE_CODE_IDE_SKIP_AUTO_INSTALL = "1";
          CLAUDE_CODE_AUTO_CONNECT_IDE = "0";
          DISABLE_NON_ESSENTIAL_MODEL_CALLS = "1";
        };
        statusLine = {
          type = "command";
          padding = 0;
          command = "ccstatusline";
          #command = "${config.home.homeDirectory}/.claude/claude-code-status.sh";
        };
        allowedDirectories = [
          "${config.home.homeDirectory}"
        ];

        extraKnownMarketplaces = { };

        enabledPlugins = { };
      };
    };
  };
}
