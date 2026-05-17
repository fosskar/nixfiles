{
  flake.modules.nixos.virtManager =
    { config, lib, ... }:
    {
      programs.virt-manager.enable = true;

      users.groups.libvirtd.members = lib.mkAfter config.users.groups.wheel.members;

      virtualisation = {
        libvirtd.enable = true;
        spiceUSBRedirection.enable = true;
      };
    };
}
