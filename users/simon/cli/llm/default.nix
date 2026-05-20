{
  mylib,
  ...
}:
{
  imports = mylib.scanPaths ./. {
    exclude = [ ];
  };

  home.file."AGENTS.md".source = ./AGENTS.md;
}
