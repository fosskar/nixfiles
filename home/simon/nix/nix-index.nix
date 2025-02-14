{
  config,
  lib,
  inputs,
  ...
}:

with lib;

let
  cfg = config.module.nix.nix-index;
in
{
  imports = [ inputs.nix-index-database.hmModules.nix-index ];

  options.module.nix.nix-index = {
    enable = mkEnableOption "Enable nix-index";
  };

  config = mkIf cfg.enable {
    programs.nix-index = {
      enable = true;
    };
  };
}
