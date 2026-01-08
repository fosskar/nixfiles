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
          command = "${config.home.homeDirectory}/.claude/claude-code-status.sh";
        };
        allowedDirectories = [
          "${config.home.homeDirectory}"
        ];

        extraKnownMarketplaces = {
          superpowers-marketplace = {
            source = {
              source = "github";
              repo = "obra/superpowers-marketplace";
            };
          };
          claude-code-workflows = {
            source = {
              source = "github";
              repo = "wshobson/agents";
            };
          };
        };

        enabledPlugins = {
          "superpowers@superpowers-marketplace" = true;
          "code-documentation@claude-code-workflows" = true;
          "cloud-infrastructure@claude-code-workflows" = true;
          "cicd-automation@claude-code-workflows" = true;
          "context7@claude-plugins-official" = true;
        };
      };
    };
  };
}
