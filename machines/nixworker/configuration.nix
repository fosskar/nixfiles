{
  self,
  nflib,
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
    self.modules.nixos.radicle
    self.modules.nixos.tangledKnot
    self.modules.nixos.tangledSpindle
    self.modules.nixos.homeManager
  ]
  ++ (nflib.scanPaths ./. { });

  srvos.boot.consoles = [ "tty0" ];

  programs.nix-ld.enable = true;
}
