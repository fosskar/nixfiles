_: {
  flake.modules.homeManager.llm =
    { inputs, pkgs, ... }:
    {
      imports = [ inputs.pi-pack.homeModules.default ];

      programs.pi-pack.enable = true;

      programs.pi-coding-agent = {
        enable = true;
        package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;
        context = ../AGENTS.md;

        settings = {
          defaultProvider = "anthropic";
          defaultModel = "claude-opus-5";
          defaultThinkingLevel = "medium";
          hideThinkingBlock = true;
          followUpMode = "all";
          steeringMode = "one-at-a-time";
          theme = "custom";
          quietStartup = true;
          enableInstallTelemetry = false;
          terminal.showTerminalProgress = true;
          warnings.anthropicExtraUsage = false;
          packages = [
            {
              source = "git:github.com/rytswd/pi-agent-extensions";
              extensions = [ "-statusline/index.ts" ];
            }
            {
              source = "git:github.com/tintinweb/pi-subagents";
            }
          ];
          compaction.enabled = true;
        };
      };
    };
}
