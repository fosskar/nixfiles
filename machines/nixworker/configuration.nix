{
  self,
  mylib,
  ...
}:
{
  imports = [
    self.modules.nixos.btrfs
    self.modules.nixos.tunedServerPowersave
    self.modules.nixos.buildbotMaster
    self.modules.nixos.buildbotWorker
    self.modules.nixos.radicle
  ]
  ++ (mylib.scanPaths ./. { });

  clan.core.settings.machine-id.enable = true;

  # zed remote server binary runs over ssh; nix-ld helps with dynamic linker deps.
  programs.nix-ld.enable = true;
}
