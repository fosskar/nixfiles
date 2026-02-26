{
  mylib,
  inputs,
  pkgs,
  ...
}:
{
  imports = mylib.scanPaths ./. {
    exclude = [ "mcp.nix" ];
  };

  home.packages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.qmd
  ];

  home.file."AGENTS.md".source = ./AGENTS.md;
}
