{
  mylib,
  ...
}:
{
  imports = mylib.scanPaths ./. {
    exclude = [ ];
  };

  xdg.configFile."AGENTS.md".source = ./AGENTS.md;
}
