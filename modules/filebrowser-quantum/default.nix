{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.filebrowser-quantum;
  format = pkgs.formats.yaml { };

  # merge user settings with defaults
  configFile = format.generate "config.yaml" (
    lib.recursiveUpdate {
      server = {
        inherit (cfg) port;
        inherit (cfg) baseURL;
        database = "/var/lib/filebrowser-quantum/database.db";
      };
    } cfg.settings
  );
in
{
  options.services.filebrowser-quantum = {
    enable = lib.mkEnableOption "filebrowser-quantum web file manager";

    package = lib.mkPackageOption pkgs "filebrowser-quantum" {
      default = [
        "custom"
        "filebrowser-quantum"
      ];
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "filebrowser-quantum";
      description = "user account under which filebrowser-quantum runs";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "filebrowser-quantum";
      description = "group under which filebrowser-quantum runs";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "port to listen on";
    };

    baseURL = lib.mkOption {
      type = lib.types.str;
      default = "/";
      description = "base URL path";
    };

    openFirewall = lib.mkEnableOption "opening firewall port for filebrowser-quantum";

    settings = lib.mkOption {
      inherit (format) type;
      default = { };
      description = ''
        additional settings for filebrowser-quantum.
        see upstream config.yaml for all options.
      '';
      example = lib.literalExpression ''
        {
          server.sources = [
            { name = "files"; path = "/srv/files"; }
          ];
          userDefaults.darkMode = true;
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.filebrowser-quantum = {
      description = "filebrowser-quantum web file manager";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package}";
        WorkingDirectory = "/var/lib/filebrowser-quantum";

        User = cfg.user;
        Group = cfg.group;

        StateDirectory = "filebrowser-quantum";
        StateDirectoryMode = "0750";

        # hardening
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        MemoryDenyWriteExecute = true;
        LockPersonality = true;
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        DevicePolicy = "closed";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
        SystemCallArchitectures = "native";
        CapabilityBoundingSet = "";
        UMask = "0077";
      };

      preStart = ''
        ln -sf ${configFile} /var/lib/filebrowser-quantum/config.yaml
      '';
    };

    users.users = lib.mkIf (cfg.user == "filebrowser-quantum") {
      filebrowser-quantum = {
        inherit (cfg) group;
        isSystemUser = true;
      };
    };

    users.groups = lib.mkIf (cfg.group == "filebrowser-quantum") {
      filebrowser-quantum = { };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
