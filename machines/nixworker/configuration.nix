{
  self,
  mylib,
  ...
}:
{
  imports = [
    self.modules.nixos.btrfs
    self.modules.nixos.systemdBoot
    self.modules.nixos.tunedServerPowersave
    self.modules.nixos.nixbot
    self.modules.nixos.codebergActionsRunner
    self.modules.nixos.hermesAgent
    self.modules.nixos.signalCli
    #self.modules.nixos.giteaMq
    self.modules.nixos.radicle
    self.modules.nixos.homeManager
  ]
  ++ (mylib.scanPaths ./. { });

  srvos.boot.consoles = [ "tty0" ];

  programs.nix-ld.enable = true;
}
