{
  mylib,
  ...
}:
{
  imports = mylib.scanPaths ./. { };

  xdg.configFile."AGENT.md".source = ./AGENT.md;
}
