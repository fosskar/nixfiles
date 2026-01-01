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
        #kagimcp = {
        #  args = [
        #    "shell"
        #    "nixpkgs#uv"
        #    "-c"
        #    "uvx"
        #    "kagimcp"
        #  ];
        #  command = "nix";
        #  env = {
        #    KAGI_API_KEY = "your-api-key-here";
        #  };
        #  type = "stdio";
        #};
      };
    };
  };
}
