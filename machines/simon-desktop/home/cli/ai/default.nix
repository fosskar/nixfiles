{
  mylib,
  ...
}:
{
  imports = mylib.scanPaths ./. { };

  xdg.configFile."opencode/AGENTS.md".source = ./AGENTS.md;
}
