{
  config,
  lib,
  ...
}:
with lib;

let
  cfg = config.module.terminal.programs.dircolors;
in
{
  options.module.terminal.programs.dircolors = {
    enable = mkEnableOption "Enable dircolors";
  };

  config = mkIf cfg.enable {
    programs = {
      dircolors = {
        enable = true;
      };
    };
  };
}
