_: {
  flake.modules.homeManager.llm =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      extensionFiles = builtins.readDir ../extensions;
      extensionEntries = lib.mapAttrs' (
        name: _: lib.nameValuePair ".pi/agent/extensions/${name}" { source = ../extensions/${name}; }
      ) extensionFiles;
    in
    {
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
            }
            {
              source = "git:github.com/tintinweb/pi-subagents";
            }
            {
              source = "git:github.com/pasky/pi-omplike-advisor";
            }
          ];
          compaction.enabled = true;
        };
      };

      home.packages = [ pkgs.local.sediment ];

      home.file = extensionEntries // {
        ".pi/agent/extensions/memory.ts".source = pkgs.replaceVars ../extensions/memory.ts {
          SEDIMENT_BIN = lib.getExe pkgs.local.sediment;
        };
        ".pi/agent/modes.json".text = builtins.toJSON {
          modes.advisor = {
            provider = "anthropic";
            modelId = "claude-sonnet-5";
            thinkingLevel = "low";
          };
        };
      };
    };
}
