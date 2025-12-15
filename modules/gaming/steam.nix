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
  config = lib.mkIf (cfg.enable && cfg.steam.enable) {
    programs.steam = {
      enable = true;
      localNetworkGameTransfers.openFirewall = cfg.steam.localNetworkTransfer;
      remotePlay.openFirewall = cfg.steam.remotePlay;
      # NOTE: gamescopeSession.enable is required for gamescope to work in steam
      # without this, gamescope inside steam games will not function
      gamescopeSession.enable = cfg.gamescope.steamSession;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
      package = pkgs.steam.override {
        extraEnv = {
          PROTON_ENABLE_WAYLAND = 1;
          PROTON_USE_NTSYNC = 1;
        };
      };
    };
  };
}
