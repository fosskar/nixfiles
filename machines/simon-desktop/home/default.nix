{
  mylib,
  pkgs,
  ...
}:
{
  # desktop-specific home-manager config
  home-manager.users.simon = {
    imports = mylib.scanPaths ./. { };
    home.packages = [ pkgs.teamspeak6-client ];
  };
}
