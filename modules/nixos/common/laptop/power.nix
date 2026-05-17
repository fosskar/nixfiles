{ config, ... }:
{
  flake.modules.nixos.laptop =
    { ... }:
    {
      imports = with config.flake.modules.nixos; [
        logind
        powertop
        suspendThenShutdown
        tunedPpd
        upower
      ];

      boot.kernelParams = [
        # use native screen backlight interface for systemd-backlight restore
        "acpi_backlight=native"
      ];

      systemd.services.nix-gc.unitConfig.ConditionACPower = true;
    };
}
