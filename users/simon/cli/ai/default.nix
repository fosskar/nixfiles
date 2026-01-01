{
  mylib,
  ...
}:
{
  imports = mylib.scanPaths ./. {
    exclude = [
      "codex"
      "gemini-cli"
    ];
  };

  xdg.configFile."AGENTS.md".source = ./AGENTS.md;
}
