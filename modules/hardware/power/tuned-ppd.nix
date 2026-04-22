{
  flake.modules.nixos.tunedPpd =
    { lib, ... }:
    {
      services.tuned = {
        ppdSupport = lib.mkForce true;
        settings.dynamic_tuning = true;
        ppdSettings.battery.balanced = "laptop-battery-powersave";
      };
    };
}
