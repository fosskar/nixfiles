{
  lib,
  mylib,
  ...
}:
{
  imports = mylib.scanPaths ./. { };

  options.nixfiles.power = {
    upower.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "enable upower for battery monitoring";
    };

    ppd.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "enable power-profiles-daemon (for desktop/laptop)";
    };

    auto-cpufreq.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "enable auto-cpufreq (automatic AC/battery CPU scaling)";
    };

    logind.enable = lib.mkEnableOption "laptop logind settings (lid/power key)";

    tuned = {
      enable = lib.mkEnableOption "tuned";

      profile = lib.mkOption {
        type = lib.types.str;
        default = "balanced";
        description = "tuned profile (server) or AC profile (laptop)";
      };

      ppdSupport = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "enable ppd API + battery auto-switching (auto-enables upower)";
      };

      batteryProfile = lib.mkOption {
        type = lib.types.str;
        default = "laptop-battery-powersave";
        description = "tuned profile when on battery (only when ppdSupport=true)";
      };
    };
  };
}
