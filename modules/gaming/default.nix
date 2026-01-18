{ lib, mylib, ... }:
{
  imports = mylib.scanPaths ./. { };

  options.nixfiles.gaming = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "gaming support";
    };

    steam = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "enable steam with proton-ge";
      };
      remotePlay = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "steam remote play (opens firewall)";
      };
      localNetworkTransfer = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "steam local network game transfers (opens firewall)";
      };
    };

    gamemode.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable gamemode for performance optimization";
    };

    gamescope = {
      # NOTE: enabling steamSession is required for gamescope to work within steam games
      # the standalone gamescope conflicts with steam's built-in gamescope session
      # if you want to use gamescope in steam, you MUST enable this
      steamSession = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "enable steam's gamescope session (required for gamescope to work in steam)";
      };
    };

    lutris = {
      enable = lib.mkEnableOption "lutris game launcher";
      wine = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "include wine packages with lutris";
      };
    };

    starCitizen.enable = lib.mkEnableOption "star citizen via rsi-launcher";
  };
}
