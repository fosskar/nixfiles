{
  self,
  mylib,
  ...
}:
{
  imports = [
    self.modules.nixos.systemdBoot
    self.modules.nixos.tunedServerPowersave
    self.modules.nixos.opencrow
    self.modules.nixos.nostrRelay
  ]
  ++ (mylib.scanPaths ./. { });

  srvos.boot.consoles = [ "tty0" ];
}
