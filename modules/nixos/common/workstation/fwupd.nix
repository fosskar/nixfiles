{
  flake.modules.nixos.workstation =
    { lib, ... }:
    {
      # firmware update daemon
      services.fwupd.enable = lib.mkDefault true;
    };
}
