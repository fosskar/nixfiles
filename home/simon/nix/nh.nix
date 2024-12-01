{ lib, config, ... }:

with lib;

let
  cfg = config.module.nix.nh;
in

{
  options.module.nix.nh = {
    enable = mkEnableOption "Enable nh";
  };

  config = mkIf cfg.enable {

    home.sessionVariables.FLAKE = "${config.home.homeDirectory}/code/nixfiles";

    programs.nh = {
      enable = true;
      flake = "${config.home.homeDirectory}/code/nixfiles";
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 3";
      };
    };
  };
}
