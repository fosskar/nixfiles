{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.beszel.agent;
in
{
  options.nixfiles.beszel.agent = {
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

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "environment file for agent secrets";
    };
  };

  config = lib.mkIf cfg.enable {
    clan.core.vars.generators.beszel = {
      share = true;
      prompts."ssh-public-key" = {
        description = "beszel agent ssh public key for hub auth";
        persist = true;
      };
      files."ssh-public-key".secret = false;
      script = ''
        cat "$prompts/ssh-public-key" > "$out/ssh-public-key"
      '';
    };

    services.beszel.agent = {
      enable = true;
      extraPath = [
        pkgs.intel-gpu-tools
        pkgs.smartmontools
      ];
      environment = {
        LISTEN = toString cfg.port;
        FILESYSTEM = cfg.filesystem;
      }
      // lib.optionalAttrs (cfg.sensors != "") {
        SENSORS = cfg.sensors;
      }
      // lib.optionalAttrs (cfg.extraFilesystems != "") {
        EXTRA_FILESYSTEMS = cfg.extraFilesystems;
      };
      inherit (cfg) environmentFile;
    };

    # hardening overrides for smart/systemd monitoring
    systemd.services.beszel-agent.serviceConfig = {
      AmbientCapabilities = "CAP_SYS_RAWIO CAP_SYS_ADMIN";
      CapabilityBoundingSet = "CAP_SYS_RAWIO CAP_SYS_ADMIN";
      SupplementaryGroups = [
        "disk"
        "video"
        "render"
      ];
      PrivateDevices = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
      NoNewPrivileges = lib.mkForce false;
      BindReadOnlyPaths = [ "/run/dbus/system_bus_socket" ];
    };
  };
}
