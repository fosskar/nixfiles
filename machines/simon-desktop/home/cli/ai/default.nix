{
  mylib,
  ...
}:
{
  imports = mylib.scanPaths ./. { };

  xdg.configFile."AGENTS.md".source = ./AGENTS.md;
}
