# netbird reverse proxy
# exposes internal services to the public internet through the netbird mesh
{
  config,
  lib,
  ...
}:

let
  cfg = config.services.netbird.server.proxy;
  stateDir = "/var/lib/netbird-proxy";
in
{
  options.services.netbird.server.proxy = {
    enable = lib.mkEnableOption "netbird reverse proxy";

    package = lib.mkOption {
      type = lib.types.package;
      description = "netbird-proxy package";
    };

    managementAddress = lib.mkOption {
      type = lib.types.str;
      description = "management server address";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      description = "base domain for proxy services (e.g. fosskar.eu → myapp.fosskar.eu)";
    };

    addr = lib.mkOption {
      type = lib.types.str;
      default = ":8443";
      description = "address the proxy listens on";
    };

    tokenFile = lib.mkOption {
      type = lib.types.str;
      description = "path to file containing the proxy access token (nbx_...)";
    };

    acmeCerts = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable automatic ACME TLS certificates";
    };

    acmeChallengeType = lib.mkOption {
      type = lib.types.str;
      default = "tls-alpn-01";
      description = "ACME challenge type";
    };

    certDir = lib.mkOption {
      type = lib.types.str;
      default = "${stateDir}/certs";
      description = "directory for TLS certificates";
    };

    allowInsecure = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "allow insecure (non-TLS) gRPC connection to management server";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.netbird-proxy = {
      description = "netbird reverse proxy";
      documentation = [ "https://docs.netbird.io/manage/reverse-proxy" ];
      after = [
        "network.target"
        "netbird-server.service"
        "netbird-proxy-token.service"
      ];
      requires = [ "netbird-proxy-token.service" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        NB_PROXY_DOMAIN = cfg.domain;
        NB_PROXY_MANAGEMENT_ADDRESS = cfg.managementAddress;
        NB_PROXY_ADDRESS = cfg.addr;
        NB_PROXY_CERTIFICATE_DIRECTORY = cfg.certDir;
        NB_PROXY_ACME_CERTIFICATES = lib.boolToString cfg.acmeCerts;
        NB_PROXY_ACME_CHALLENGE_TYPE = cfg.acmeChallengeType;
        NB_PROXY_HEALTH_ADDRESS = "localhost:8444";
        NB_PROXY_DEBUG_ENDPOINT_ADDRESS = "localhost:8445";
      }
      // lib.optionalAttrs cfg.allowInsecure {
        NB_PROXY_ALLOW_INSECURE = "true";
      };

      script = ''
        export NB_PROXY_TOKEN=$(cat ${cfg.tokenFile})
        exec ${lib.getExe cfg.package}
      '';

      serviceConfig = {
        RuntimeDirectory = "netbird-proxy";
        RuntimeDirectoryMode = "0750";
        Restart = "always";
        StateDirectory = [
          "netbird-proxy"
          "netbird"
        ];
        StateDirectoryMode = "0750";
        WorkingDirectory = stateDir;

        # hardening
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateMounts = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        AmbientCapabilities = [ "CAP_NET_ADMIN" ];
        CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
        User = "netbird";
        Group = "netbird";
      };

      stopIfChanged = false;
    };
  };
}
