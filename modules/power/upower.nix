{
  lib,
  config,
  ...
}:
let
  cfg = config.nixfiles.power.upower;
in
{
  config = lib.mkIf cfg.enable {
    services.upower.enable = true;
  };
}
