{
  flake.modules.nixos.workstation =
    { lib, config, ... }:
    {
      hardware.i2c.enable = lib.mkDefault true;

      users.groups.i2c.members = lib.mkAfter config.users.groups.wheel.members;
    };
}
