{ config, ... }:
{
  flake.modules.nixos.tunedPpd = {
    imports = [ config.flake.modules.nixos.tuned ];

    services.tuned = {
      ppdSupport = true; # overrides base mkDefault false
      settings.dynamic_tuning = true;
      ppdSettings = {
        battery.balanced = "laptop-battery-powersave";
        profiles = {
          power-saver = "powersave";
          balanced = "balanced";
          performance = "latency-performance";
        };
      };
    };
  };
}
