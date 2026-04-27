{
  flake.modules.nixos.systemdBoot =
    { lib, ... }:
    {
      boot.loader.systemd-boot = {
        enable = true;
        editor = lib.mkDefault false;
      };
    };
}
