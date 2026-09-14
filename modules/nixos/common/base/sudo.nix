{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      security = {
        sudo-rs = {
          enable = lib.mkForce true;
          execWheelOnly = lib.mkForce true;
        };

        sudo = {
          enable = lib.mkForce false;
        };
      };
    };
}
