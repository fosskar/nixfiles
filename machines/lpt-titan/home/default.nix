{
  nflib,
  self,
  ...
}:
{
  home-manager.users.simon = {
    imports = [
      self.modules.homeManager.herdr
      self.modules.homeManager.noctalia
    ]
    ++ nflib.scanPaths ./. { };
  };
}
