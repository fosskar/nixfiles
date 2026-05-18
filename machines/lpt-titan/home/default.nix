{
  mylib,
  self,
  ...
}:
{
  home-manager.users.simon = {
    imports = [
      self.modules.homeManager.noctalia-v5
    ]
    ++ mylib.scanPaths ./. { };
  };
}
