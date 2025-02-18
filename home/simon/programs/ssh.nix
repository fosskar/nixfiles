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
      addKeysToAgent = "no";
      extraConfig = ''
        StrictHostKeyChecking no
        UpdateHostKeys yes
      '';
    };
  };
}
