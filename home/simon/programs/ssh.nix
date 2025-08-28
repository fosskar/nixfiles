{
  config,
  lib,
  ...
}:
with lib;

let
  cfg = config.module.programs.ssh;
in
{
  options.module.programs.ssh = {
    enable = mkEnableOption "Enable module";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          addKeysToAgent = "no";
          extraOptions = {
            UpdateHostKeys = "yes";
          };
        };
      };
    };
  };
}
