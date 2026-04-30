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
    self.modules.nixos.buildbotMaster
    self.modules.nixos.buildbotWorker
    self.modules.nixos.giteaMq
    self.modules.nixos.radicle
  ]
  ++ (mylib.scanPaths ./. { });

  srvos.boot.consoles = [ "tty0" ];

  # zed remote server binary runs over ssh; nix-ld helps with dynamic linker deps.
  programs.nix-ld.enable = true;
}
