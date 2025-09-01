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

    programs.nh = {
      enable = true;
      flake = "${config.home.homeDirectory}/code/nixfiles";
      clean = {
        enable = true;
        extraArgs = "--keep 5 --keep-since 3d";
      };
    };
  };
}
