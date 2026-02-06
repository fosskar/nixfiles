{ mylib, ... }:
{
  imports = [
    ../../modules/power
    ../../modules/persistence
    ../../modules/tailscale
  ]
  ++ (mylib.scanPaths ./. { exclude = [ ]; });

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

  users.users.root.linger = true;

  boot = {
    supportedFilesystems = [ "btrfs" ];
    initrd.supportedFilesystems = [ "btrfs" ];
  };
}
