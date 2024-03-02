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

    nameservers = mkOption {
      type = types.listOf types.str;
      default = ["192.168.178.91"];
      description = "DNS nameservers.";
    };

    resolved = mkOption {
      type = types.attrs;
      default = {};
      description = "Systemd-resolved settings.";
    };

    tailscale = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable Tailscale.";
    };

    networkManagerWaitOnline = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable NetworkManager-wait-online.";
    };
  };

  config = {
    networking.hostName = cfg.hostName;
    networking.networkmanager.enable = cfg.networkManager;
    networking.nameservers = cfg.nameservers;

    services.resolved = {
      enable = true; # Assuming you always want this enabled as per your config
      domains = cfg.resolved.domains or ["space"];
      dnssec = cfg.resolved.dnssec or false;
    };

    systemd.services.NetworkManager-wait-online.enable = cfg.networkManagerWaitOnline;

    services.tailscale.enable = cfg.tailscale;
  };
}
