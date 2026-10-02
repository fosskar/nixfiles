_: {
  flake.modules.homeManager.llm =
    { inputs, pkgs, ... }:
    {
      imports = [ inputs.pi-pack.homeModules.default ];

      programs.pi-pack.enable = true;

      programs.git.ignores = [ ".pi/" ];

      programs.pi-coding-agent = {
        enable = true;
        package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;
        context = ../AGENTS.md;

        settings = {
          defaultProvider = "anthropic";
          defaultModel = "claude-opus-5-5";
          hideThinkingBlock = true;
          followUpMode = "all";
          theme = "grey-teal";
          quietStartup = "header";
          collapseChangelog = true;
          enableInstallTelemetry = false;
          defaultTools = [ "+codemode" ];
          warnings.anthropicExtraUsage = false;
          packages = [
            {
              source = "git:github.com/rytswd/pi-agent-extensions";
              extensions = [ "-statusline/index.ts" ];
            }
          ];
        };
      };
    };
}
