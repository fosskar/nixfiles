{
  config,
  lib,
  ...
}:
with lib;

let
  cfg = config.module.terminal.programs.gemini-cli;
in
{
  options.module.terminal.programs.gemini-cli = {
    enable = mkEnableOption "Enable gemini-cli";
  };

  config = mkIf cfg.enable {
    programs.gemini-cli = {
      enable = true;
    };
  };
}
