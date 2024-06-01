{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.myNetwork;
in {
  options.myNetwork = {
    hostName = mkOption {
      type = types.str;
      default = "nixos";
      description = "The host name for the system.";
    };

    networkManager = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable NetworkManager.";
    };

    wireless = mkOption {
      type = types.bool;
      default = false; # Default to false, overridden as needed
      description = "Whether to enable wireless.";
    };

    extraHosts = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra hosts for /etc/hosts.";
    };

    tailscale = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable Tailscale.";
    };

    networkManagerWaitOnline = mkOption {
      type = types.bool;
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
