_: {
  flake.modules.homeManager.sediment =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      sediment = pkgs.local.sediment;
      # the store pi-pack's sediment-memory extension wrote to
      db = "${config.xdg.stateHome}/sediment/data";
      server = {
        command = lib.getExe sediment;
        env.SEDIMENT_DB = db;
      };
      # pi and omp read the common mcpServers format; home-manager has no integration for them
      mcpJson = (pkgs.formats.json { }).generate "sediment-mcp.json" {
        mcpServers.sediment = server;
      };
    in
    {
      programs.mcp = {
        enable = true;
        servers.sediment = server;
      };
      programs.claude-code.enableMcpIntegration = true;
      programs.codex.enableMcpIntegration = true;
      programs.opencode.enableMcpIntegration = true;

      home.file.".pi/agent/mcp.json".source = mcpJson;
      home.file.".omp/agent/mcp.json".source = mcpJson;

      # every harness stores explicitly through the mcp server
      programs.pi-pack.extensions = lib.remove "sediment-memory" inputs.pi-pack.lib.extensions;

      home.packages = [ sediment ];
      home.sessionVariables.SEDIMENT_DB = db;
    };
}
