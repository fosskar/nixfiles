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
          hideThinkingBlock = true;
          followUpMode = "all";
          steeringMode = "one-at-a-time";
          theme = "custom";
          quietStartup = true;
          enableInstallTelemetry = false;
          terminal.showTerminalProgress = true;
          packages = [
            {
              source = "git:github.com/rytswd/pi-agent-extensions";
              extensions = [ "!permission-gate" ];
            }
            {
              # v0.10.4
              source = "git:github.com/tintinweb/pi-subagents@b717012e170f9acaa5b756456e9636d12a6e2f2a";
            }
          ];
          compaction.enabled = true;
        };
      };

      home.file = extensionEntries;
    };
}
