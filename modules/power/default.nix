{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.power;
in
{
  options.nixfiles.power = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable power management";
    };

    backend = lib.mkOption {
      type = lib.types.enum [
        "power-profiles-daemon"
        "tuned"
        "none"
      ];
      default = "power-profiles-daemon";
      description = "power management backend";
    };
  };

  config = lib.mkIf cfg.enable {
    services.power-profiles-daemon.enable = lib.mkIf (cfg.backend == "power-profiles-daemon") true;

    # tuned support (future)
    # services.tuned.enable = lib.mkIf (cfg.backend == "tuned") true;

    environment.systemPackages = lib.mkIf (cfg.backend == "power-profiles-daemon") [
      pkgs.power-profiles-daemon
    ];
  };
}
