{
  mylib,
  ...
}:
{
  # desktop-specific home-manager config
  home-manager.users.simon = {
    imports = mylib.scanPaths ./. { };
    nixfiles = {
      machineType = "desktop";
      quickshell = "dms";
    };
  };
}
