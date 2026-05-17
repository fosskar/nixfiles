{
  flake.modules.nixos.server =
    { lib, ... }:
    {
      hardware.bluetooth.enable = lib.mkForce false;
    };
}
