{
  mylib,
  ...
}:
{
  # laptop-specific home-manager config
  home-manager.users.simon.imports = mylib.scanPaths ./. { };
}
