{
  config,
  lib,
  ...
}:
with lib;

let
  cfg = config.module.terminal.programs.fzf;
in
{
  options.module.terminal.programs.fzf = {
    enable = mkEnableOption "Enable fzf";
  };

  config = mkIf cfg.enable {
    programs.fzf = {
      enable = true;
    };
  };
}
