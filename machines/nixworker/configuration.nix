{ mylib, ... }:
{
  imports = [
    ../../modules/filesystems/btrfs.nix
    ../../modules/power
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
}
