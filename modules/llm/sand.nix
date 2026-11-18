_: {
  flake.modules.homeManager.sand =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      sand = inputs.sand.packages.${pkgs.stdenv.hostPlatform.system}.sand;
      # the store keeps its sediment-era path; moving it is a manual step on every machine
      db = "${config.xdg.stateHome}/sediment/data";
      server = {
        command = lib.getExe sand;
        env.SAND_DB = db;
      };
      # pi and omp read the common mcpServers format; home-manager has no integration for them
      mcpJson = (pkgs.formats.json { }).generate "sand-mcp.json" {
        mcpServers.sand = server;
      };
      # pi's default codemode exposure hides the tools until the model searches for them
      piMcpJson = (pkgs.formats.json { }).generate "sand-pi-mcp.json" {
        mcpServers.sand = server // {
          exposure = "direct";
        };
      };
      # claude-code and codex run this on each prompt; the pi and omp extension calls it too.
      # the wrapper keeps the command name stable (codex asks to trust a hook again when it
      # changes) and passes the store, because a harness may not inherit SAND_DB
      recallHook = pkgs.writeShellApplication {
        name = "sand-recall-hook";
        runtimeInputs = [ sand ];
        text = ''
          exec sand --db ${lib.escapeShellArg db} hook recall
        '';
      };
      # pi and omp pick the parser from the store path, so the name must end in .ts
      recallExtension = pkgs.replaceVars ./sand-recall.ts { recallHook = lib.getExe recallHook; };
      recallCommand = {
        type = "command";
        # a bare name keeps the hook definition stable; codex asks to trust a hook again when it changes
        command = "sand-recall-hook";
        timeout = 10;
      };
    in
    {
      programs.mcp = {
        enable = true;
        servers.sand = server;
      };
      programs.claude-code.enableMcpIntegration = true;
      programs.codex.enableMcpIntegration = true;
      programs.opencode.enableMcpIntegration = true;

      home.file.".pi/agent/mcp.json".source = piMcpJson;
      home.file.".omp/agent/mcp.json".source = mcpJson;

      # recall hooks: the harness runs recall at the start of a session, so recall does not depend on the model
      programs.claude-code.settings.hooks.UserPromptSubmit = [ { hooks = [ recallCommand ]; } ];
      home.file.".codex/hooks.json".source = (pkgs.formats.json { }).generate "codex-hooks.json" {
        hooks.UserPromptSubmit = [ { hooks = [ recallCommand ]; } ];
      };
      home.file.".pi/agent/extensions/sand-recall.ts".source = recallExtension;
      home.file.".omp/agent/extensions/sand-recall.ts".source = recallExtension;

      home.packages = [
        sand
        recallHook
      ];
      home.sessionVariables.SAND_DB = db;
    };
}
