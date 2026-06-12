{
  nflib,
  self,
  ...
}:
{
  home-manager.users.simon = {
    imports = [
      self.modules.homeManager.gaming
      self.modules.homeManager.noctalia
    ]
    ++ nflib.scanPaths ./. { };
  };
}
