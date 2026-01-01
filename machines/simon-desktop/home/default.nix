{
  mylib,
  ...
}:
{
  # desktop-only home-manager overrides (gaming)
  home-manager.users.simon.imports = mylib.scanPaths ./. { };
}
