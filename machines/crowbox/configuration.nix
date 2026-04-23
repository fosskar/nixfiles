{
  self,
  mylib,
  ...
}:
{
  imports = [
    self.modules.nixos.btrfs
    self.modules.nixos.tunedServerPowersave
    self.modules.nixos.preservation
    self.modules.nixos.opencrow
    self.modules.nixos.nostrRelay
  ]
  ++ (mylib.scanPaths ./. { exclude = [ "signal-cli.nix" ]; });

  nixpkgs.hostPlatform = "x86_64-linux";

  nixfiles = {
    preservation = {
      rollback = {
        type = "btrfs";
        deviceLabel = "root";
      };
      directories = [
        "/root"
      ];
    };
  };

  clan.core.settings.machine-id.enable = true;
}
