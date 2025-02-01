{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.module.gaming.star-citizen;

  #fixes gamemode when using omu-launcher. See https://github.com/FeralInteractive/gamemode/issues/254#issuecomment-643648779
  gamemodeSharedObjects = lib.concatMapStringsSep ":" (v: "${lib.getLib pkgs.gamemode}/lib/${v}") [
    "libgamemodeauto.so"
    "libgamemode.so"
  ];

  star-citizen = inputs.nix-gaming.packages.${pkgs.system}.star-citizen.override (_prev: {
    useUmu = true;
    gameScopeEnable = true;
    gameScopeArgs = [
      "-W 3440"
      "-H 1440"
      "-w 3440"
      "-h 1440"
      "-r 165"
      #"--force-grab-cursor"
      "-b"
      #"--adaptive-sync"
      "--backend=wayland"
      "--mangoapp"
      # HDR
      #"--hdr-enabled"
    ];
    preCommands = ''
      export LD_PRELOAD="${gamemodeSharedObjects}"
      export dual_color_blend_by_location="true"
      # mesa shader cache
      export MESA_SHADER_CACHE_DIR="$WINEPREFIX"
      export MESA_SHADER_CACHE_MAX_SIZE=10G
    '';
  });
in
{
  options.module.gaming.star-citizen = {
    enable = mkEnableOption "Enable star-citizen";
  };

  config = mkIf cfg.enable {

    home.packages = [
      star-citizen
    ];
  };
}
