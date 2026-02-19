{
  mylib,
  inputs,
  pkgs,
  ...
}:
{
  imports = mylib.scanPaths ./. {
    exclude = [ ];
  };

  home.packages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
  ];

  xdg.configFile."AGENTS.md".source = ./AGENTS.md;
}
