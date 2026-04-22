{
  flake.modules.nixos.steam =
    { pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        localNetworkGameTransfers.openFirewall = true;
        remotePlay.openFirewall = true;
        # gamescopeSession required for gamescope to work in steam games
        gamescopeSession.enable = true;
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
