_: {
  programs = {
    claude-code = {
      mcpServers = {
        nixos = {
          args = [
            "run"
            "github:utensils/mcp-nixos"
            "--"
          ];
          command = "nix";
        };
        "plugin:context7:context7" = {
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
      };
    };
  };
}
