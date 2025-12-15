{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.gaming;
in
{
  config = lib.mkIf (cfg.enable && cfg.lutris.enable) {
    environment.systemPackages = [
      (pkgs.lutris.override {
        extraPkgs = pkgs: lib.optionals cfg.lutris.wine [ pkgs.wineWowPackages.stable ];
      })
    ];
  };
}
