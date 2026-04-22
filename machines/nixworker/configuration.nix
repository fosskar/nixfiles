{
  self,
  mylib,
  ...
}:
{
  imports = [
    self.modules.nixos.btrfs
    self.modules.nixos.tuned
    self.modules.nixos.buildbotMaster
    self.modules.nixos.buildbotWorker
    self.modules.nixos.radicle
  ]
  ++ (mylib.scanPaths ./. { });

  nixpkgs.hostPlatform = "x86_64-linux";

  nixfiles = {
    tuned.profile = "server-powersave";
  };

  clan.core.settings.machine-id.enable = true;

  # zed remote server binary runs over ssh; nix-ld helps with dynamic linker deps.
  programs.nix-ld.enable = true;
}
