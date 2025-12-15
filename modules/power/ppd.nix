{
  lib,
  config,
  ...
}:
let
  cfg = config.nixfiles.power.ppd;
in
{
  config = lib.mkIf cfg.enable {
    services.power-profiles-daemon.enable = true;
  };
}
