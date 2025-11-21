_: {
  programs = {
    mcp.servers = {
      nixos = {
        args = [
          "run"
          "github:utensils/mcp-nixos"
          "--"
        ];
        command = "nix";
      };
      context7 = {
        args = [
          "shell"
          "nixpkgs#nodejs"
          "-c"
          "npx"
          "-y"
          "@upstash/context7-mcp"
        ];
        command = "nix";
        type = "stdio";
      };
      sequential-thinking = {
        command = "nix";
        args = [
          "shell"
          "nixpkgs#nodejs"
          "-c"
          "npx"
          "-y"
          "@modelcontextprotocol/server-sequential-thinking"
        ];
      };
    };
  };
}
