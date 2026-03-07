{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.monitoring.beszel;
in
{
  # --- options ---

  options.nixfiles.monitoring.beszel = {
    hub.enable = lib.mkEnableOption "beszel monitoring hub";

    agent = {
      enable = lib.mkEnableOption "beszel monitoring agent";

      port = lib.mkOption {
        type = lib.types.port;
        default = 45876;
        description = "port for beszel agent to listen on";
      };

      sensors = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "sensors to exclude (prefix with -)";
        example = "-nct6798_cputin,-nct6798_auxtin0";
      };

      filesystem = lib.mkOption {
        type = lib.types.str;
        default = "/";
        description = "primary filesystem to monitor";
      };

      extraFilesystems = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "extra filesystems (format: /path__Label,/path2__Label2)";
        example = "/nix__Nix,/tank__Tank";
      };
    };
  };

  config = lib.mkMerge [
    # --- service (hub) ---

    (lib.mkIf cfg.hub.enable {
      services.beszel.hub = {
        enable = true;
        host = "127.0.0.1";
        port = 8090;
      };

      # --- nginx ---

      nixfiles.nginx.vhosts.beszel.port = config.services.beszel.hub.port;
    })

    # --- service (agent) ---

    (lib.mkIf cfg.agent.enable {
      services.beszel.agent = {
        enable = true;
        extraPath = [
          pkgs.intel-gpu-tools
          pkgs.smartmontools
        ];
        environment = {
          LISTEN = toString cfg.agent.port;
          FILESYSTEM = cfg.agent.filesystem;
        }
        // lib.optionalAttrs (cfg.agent.sensors != "") {
          SENSORS = cfg.agent.sensors;
        }
        // lib.optionalAttrs (cfg.agent.extraFilesystems != "") {
          EXTRA_FILESYSTEMS = cfg.agent.extraFilesystems;
        };
      };

      # --- systemd ---

      # hardening overrides for smart/systemd monitoring
      systemd.services.beszel-agent.serviceConfig = {
        AmbientCapabilities = "CAP_SYS_RAWIO CAP_SYS_ADMIN";
        CapabilityBoundingSet = "CAP_SYS_RAWIO CAP_SYS_ADMIN";
        SupplementaryGroups = [ "disk" ];
        PrivateUsers = lib.mkForce false;
        NoNewPrivileges = lib.mkForce false;
        # systemd monitoring requires dbus access
        BindReadOnlyPaths = [ "/run/dbus/system_bus_socket" ];
      };
    })
  ];
}
