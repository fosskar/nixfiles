{ mylib, ... }:
{
  imports = [
    ../../modules/filesystems/btrfs.nix
    ../../modules/power
    ../../modules/buildbot
    ../../modules/radicle
  ]
  ++ (mylib.scanPaths ./. { });

  nixpkgs.hostPlatform = "x86_64-linux";

  nixfiles = {
    power.tuned = {
      enable = true;
      profile = "server-powersave";
    };
  };

  clan.core.settings.machine-id.enable = true;

  # zed remote server binary runs over ssh; nix-ld helps with dynamic linker deps.
  programs.nix-ld.enable = true;
}
