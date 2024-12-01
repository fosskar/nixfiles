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

    home.sessionVariables.FLAKE = "${config.users.users.simon.home}/code/nixfiles";

    programs.nh = {
      enable = true;
      flake = "${config.users.users.simon.home}/code/nixfiles";
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 3";
      };
    };
  };
}
