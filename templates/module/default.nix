{
  config,
  lib,
  ...
}:

let
  cfg = config.module;
in
{
  options.module = {
    enable = lib.mkEnableOption "Enable module";
  };

  config = lib.mkIf cfg.enable { };
}
