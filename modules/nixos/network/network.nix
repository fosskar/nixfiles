{ lib, config, ... }:
let
  cfg = config.myNetwork;
in
{
  options.myNetwork = {
    hostName = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
      description = "The host name for the system.";
    };

    networkManager = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable NetworkManager.";
    };

    wireless = lib.mkOption {
      type = lib.types.bool;
      default = false; # Default to false, overridden as needed
      description = "Whether to enable wireless.";
    };

    extraHosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra hosts for /etc/hosts.";
    };

    tailscale = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable Tailscale.";
    };

    networkManagerWaitOnline = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable NetworkManager-wait-online.";
    };
  };

  config = {
    networking = {
      inherit (cfg) hostName;
      networkmanager.enable = cfg.networkManager;
    };

    systemd.services.NetworkManager-wait-online.enable = cfg.networkManagerWaitOnline;

    services.tailscale.enable = cfg.tailscale;
  };
}
