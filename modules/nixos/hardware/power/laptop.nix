{ config, ... }:
{
  flake.modules.nixos.laptopPower = {
    imports = with config.flake.modules.nixos; [
      logind
      powertop
      suspendThenShutdown
      tunedPpd
      upower
    ];

    systemd.services.nix-gc.unitConfig.ConditionACPower = true;
  };
}
