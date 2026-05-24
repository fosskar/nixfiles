{ config, ... }:
{
  flake.modules.nixos.laptop =
    { ... }:
    {
      imports = [
        config.flake.modules.nixos.logind
        config.flake.modules.nixos.powertop
        config.flake.modules.nixos.tunedPpd
        config.flake.modules.nixos.upower
      ];

      boot.kernelParams = [
        # use native screen backlight interface for systemd-backlight restore
        "acpi_backlight=native"
      ];

      systemd.services.nix-gc.unitConfig.ConditionACPower = true;
    };
}
