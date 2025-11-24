{
  config,
  mylib,
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
      settings = {
        theme = "dark";
        includeCoAuthoredBy = false;
        autoUpdates = false;
        env = {
          CLAUDE_CODE_ENABLE_TELEMETRY = "0";
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
          DISABLE_ERROR_REPORTING = "1";
          DISABLE_TELEMETRY = "1";
          DISABLE_AUTOUPDATER = "1";
          CLAUDE_CODE_IDE_SKIP_AUTO_INSTALL = "1";
        };
        statusLine = {
          type = "command";
          padding = 0;
          command = "${config.home.homeDirectory}/.claude/claude-code-status.sh";
        };
        allowedDirectories = [
          "${config.home.homeDirectory}/code"
          "${config.xdg.configHome}"
        ];
        permissions = {

          #additionalDirectories = [
          #  "../docs/"
          #];
          #ask = [
          #  "Bash(git push:*)"
          #];

          allow = [
            "Bash(awk:*)"
            "Bash(cat:*)"
            "Bash(bat:*)"
            "Bash(echo:*)"
            "Bash(cp:*)"
            "Bash(env)"
            "Bash(find:*)"
            "Bash(claude mcp:*)"
            "Bash(grep:*)"
            "Bash(ls:*)"
            "Bash(mkdir:*)"
            "Bash(mv:*)"
            "Bash(sed:*)"
            "mcp__sequential-thinking__sequentialthinking"
            "mcp__context7__get-library-docs"
            "mcp__context7__resolve-library-id"
            "WebFetch(domain:docs.anthropic.com)"
            "WebFetch(domain:github.com)"
          ];

          #deny = [
          #  "WebFetch"
          #  "Bash(curl:*)"
          #  "Read(./.env)"
          #  "Read(./secrets/**)"
          #];

          #defaultMode = "acceptEdits";
        };
      };
    };
  };
}
