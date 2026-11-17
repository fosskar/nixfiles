_: {
  flake.modules.homeManager.llm =
    { inputs, pkgs, ... }:
    {
      imports = [ inputs.pi-pack.homeModules.default ];

      programs.pi-pack.enable = true;

      programs.git.ignores = [ ".pi/" ];

      programs.pi-coding-agent = {
        enable = true;
        # reply style lives in ../AGENTS.md, so pi-emphasis only renders
        package = pkgs.symlinkJoin {
          name = "pi-wrapped";
          paths = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/pi --set PI_EMPHASIS_GUIDANCE 0
          '';
        };
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
            { source = "git:github.com/rytswd/pi-agent-extensions"; }
            { source = "git:github.com/championswimmer/pi-subagent-manager@v1.9.0"; }
            { source = "git:github.com/johnlindquist/pi-emphasis"; }
          ];
        };
      };
    };
}
