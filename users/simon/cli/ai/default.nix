{
  mylib,
  pkgs,
  ...
}:
{
  imports = mylib.scanPaths ./. {
    exclude = [ ];
  };

  home.packages = [
    pkgs.llm-agents.handy
  ];

  xdg.configFile."AGENTS.md".source = ./AGENTS.md;
}
