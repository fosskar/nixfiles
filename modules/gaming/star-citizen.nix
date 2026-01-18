{
  lib,
  config,
  inputs,
  ...
}:
let
  cfg = config.nixfiles.gaming;

  #fixes gamemode when using umu-launcher. See https://github.com/FeralInteractive/gamemode/issues/254#issuecomment-643648779
  #gamemodeSharedObjects = lib.concatMapStringsSep ":" (v: "${lib.getLib pkgs.gamemode}/lib/${v}") [
  #  "libgamemodeauto.so"
  #  "libgamemode.so"
  #];
in
{
  imports = [
    inputs.nix-citizen.nixosModules.default
  ];

  config = lib.mkIf (cfg.enable && cfg.starCitizen.enable) {
    programs.rsi-launcher = {
      enable = true;
      umu.enable = true;
      gamescope = {
        enable = true;
        args = [
          "-f"
          "--expose-wayland"
          "--force-grab-cursor"
          "--force-windows-fullscreen"
          "-W 3440"
          "-H 1440"
          "-w 3440"
          "-h 1440"
          "-r 165"
          "--adaptive-sync"
          "--backend=wayland"
          # HDR
          #"--hdr-enabled"
        ];
      };
      #enforceWaylandDrv = true;
      #preCommands = ''
      #  #export LD_PRELOAD=${gamemodeSharedObjects};
      #  #export DXVK_HUD=compiler;
      #  #export MANGO_HUD=1;
      #'';
    };
  };
}
