{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      services.fwupd.enable = lib.mkDefault true;
    };
}
