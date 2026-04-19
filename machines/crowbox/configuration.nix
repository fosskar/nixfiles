{ mylib, ... }:
{
  imports = [
    ../../modules/filesystems/btrfs.nix
    ../../modules/power
    ../../modules/persistence
    ../../modules/opencrow
  ]
  ++ (mylib.scanPaths ./. { exclude = [ "signal-cli.nix" ]; });

  nixpkgs.hostPlatform = "x86_64-linux";

  nixfiles = {
    persistence = {
      enable = true;
      rollback = {
        type = "btrfs";
        deviceLabel = "root";
      };
      directories = [
        "/root"
      ];
    };

    power.tuned = {
      enable = true;
      profile = "server-powersave";
    };
  };

  clan.core.settings.machine-id.enable = true;
}
