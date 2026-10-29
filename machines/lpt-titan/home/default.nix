{
  nflib,
  self,
  ...
}:
{
  home-manager.users.simon = {
    imports = [
      self.modules.homeManager.herdrApp
      self.modules.homeManager.herdrCore
      self.modules.homeManager.noctalia
    ]
    ++ nflib.scanPaths ./. { };
  };
}
