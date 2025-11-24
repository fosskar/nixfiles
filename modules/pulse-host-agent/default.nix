{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.pulse-host-agent;
in
{
  options.services.pulse-host-agent = {
    enable = lib.mkEnableOption "pulse host agent for monitoring standalone servers";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.pulse-host-agent or (pkgs.callPackage ../../pkgs/pulse-host-agent { });
      defaultText = lib.literalExpression "pkgs.pulse-host-agent";
      description = "the pulse-host-agent package to use";
    };

    url = lib.mkOption {
      type = lib.types.str;
      example = "https://pulse.example.com";
      description = "pulse server url";
    };

    tokenFile = lib.mkOption {
      type = lib.types.path;
      example = "/run/secrets/pulse-token";
      description = "path to file containing the pulse api token with host-agent:report scope";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "30s";
      example = "1m";
      description = "reporting interval (e.g. 30s, 1m, 5m)";
    };

    hostname = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "my-server";
      description = "override hostname reported to pulse (defaults to system hostname)";
    };

    tags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "production"
        "lxc"
      ];
      description = "tags to apply to this host";
    };

    insecure = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "skip tls certificate verification (testing only)";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.pulse-host-agent = {
      description = "pulse host agent";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart =
          let
            args = [
              "${cfg.package}/bin/pulse-host-agent"
              "--url ${cfg.url}"
              "--interval ${cfg.interval}"
            ]
            ++ lib.optional (cfg.hostname != null) "--hostname ${cfg.hostname}"
            ++ lib.optionals (cfg.tags != [ ]) (map (tag: "--tag ${tag}") cfg.tags)
            ++ lib.optional cfg.insecure "--insecure";
          in
          "${pkgs.writeShellScript "pulse-host-agent-start" ''
            set -euo pipefail
            TOKEN=$(cat ${cfg.tokenFile})
            exec ${lib.escapeShellArgs args} --token "$TOKEN"
          ''}";

        Restart = "always";
        RestartSec = "5s";

        # hardening
        DynamicUser = false;
        User = "root"; # needs root for full system metrics
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
        PrivateDevices = false; # needs access to /sys for sensors
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        PrivateMounts = true;
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
        SystemCallArchitectures = "native";
      };
    };
  };
}
