{
  config,
  lib,
  ...
}:
with lib;

let
  cfg = config.module.terminal.programs.direnv;
in
{
  options.module.terminal.programs.direnv = {
    enable = mkEnableOption "Enable direnv";
  };

  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      silent = true;
    };
  };
}
