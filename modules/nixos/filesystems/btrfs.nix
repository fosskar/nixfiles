{
  flake.modules.nixos.btrfs = {
    boot = {
      supportedFilesystems = [ "btrfs" ];
      initrd.supportedFilesystems = [ "btrfs" ];
    };
  };
}
