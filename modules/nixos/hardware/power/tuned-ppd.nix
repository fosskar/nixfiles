{ config, ... }:
{
  flake.modules.nixos.tunedPpd =
    { lib, ... }:
    {
      imports = [ config.flake.modules.nixos.tuned ];

      services.tuned = {
        ppdSupport = lib.mkForce true;
        settings.dynamic_tuning = true;
        ppdSettings.battery.balanced = "laptop-battery-powersave";
      };
    };
}
