# netbird reverse proxy
# when enabled, sets up:
# - traefik routes for dashboard/API/gRPC + TLS passthrough for proxy
# - nginx to serve dashboard static files on internal port
# - proxy token generation on first boot
# - the proxy service itself
# requires: modules/traefik for base traefik config (entrypoints, acme, etc)
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.netbird.server.proxy;
  serverCfg = config.services.netbird.server;
  dashboardCfg = config.services.netbird.server.dashboard;
  stateDir = "/var/lib/netbird-proxy";
in
{
  # --- options ---

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

    dashboardPort = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "internal port where nginx serves the dashboard";
    };

    serverPort = lib.mkOption {
      type = lib.types.port;
      default = 8081;
      description = "internal port where netbird-server listens";
    };

  };

  config = lib.mkIf cfg.enable {

    # --- systemd ---

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
        StateDirectory = "netbird-proxy";
        StateDirectoryMode = "0750";
        UMask = "0077";
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

    # generate proxy access token on first boot
    systemd.services.netbird-proxy-token = {
      description = "generate netbird proxy access token";
      after = [ "netbird-server.service" ];
      requires = [ "netbird-server.service" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = "!/var/lib/netbird-server/proxy-token";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "netbird";
        Group = "netbird";
        StateDirectory = "netbird-server";
      };
      script = ''
        # wait for server to be ready
        ready=0
        for i in $(seq 1 30); do
          if ${pkgs.curl}/bin/curl -sf http://localhost:${toString cfg.serverPort}/api/users >/dev/null 2>&1; then
            ready=1
            break
          fi
          sleep 2
        done
        if [ "$ready" -ne 1 ]; then
          echo "netbird server did not become ready after 60s" >&2
          exit 1
        fi
        TOKEN=$(${serverCfg.package}/bin/netbird-server token create \
          --config /var/lib/netbird-server/config.yaml \
          --name proxy --expires-in 3650d 2>&1 | grep -oP 'nbx_\S+')
        echo -n "$TOKEN" > /var/lib/netbird-server/proxy-token
        chmod 600 /var/lib/netbird-server/proxy-token
      '';
    };

    # --- nginx ---

    services.nginx = lib.mkIf dashboardCfg.enable {
      enable = true;
      defaultHTTPListenPort = cfg.dashboardPort;
      virtualHosts.dashboard = {
        listen = [
          {
            addr = "127.0.0.1";
            port = cfg.dashboardPort;
          }
        ];
        root = dashboardCfg.finalDrv;
        locations."/".tryFiles = "$uri $uri.html $uri/ =404";
        extraConfig = ''
          error_page 404 /404.html;
          add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
          add_header X-Content-Type-Options "nosniff" always;
          add_header X-Frame-Options "DENY" always;
          add_header Referrer-Policy "strict-origin-when-cross-origin" always;
        '';
      };
    };

    # netbird proxy needs zero timeouts for long-lived tunnel connections
    services.traefik.staticConfigOptions = {
      entryPoints.websecure = {
        allowACMEByPass = true;
        transport.respondingTimeouts = {
          readTimeout = "0s";
          writeTimeout = "0s";
          idleTimeout = "0s";
        };
      };
      serversTransport.forwardingTimeouts = {
        responseHeaderTimeout = "0s";
        idleConnTimeout = "0s";
      };
    };

    services.traefik.dynamicConfigOptions = {
      http = {
        routers = {
          # gRPC — needs h2c backend (highest priority)
          netbird-grpc = {
            rule = "Host(`${serverCfg.domain}`) && (PathPrefix(`/signalexchange.SignalExchange/`) || PathPrefix(`/management.ManagementService/`) || PathPrefix(`/management.ProxyService/`))";
            service = "netbird-server-h2c";
            entryPoints = [ "websecure" ];
            tls.certResolver = "letsencrypt";
            priority = 100;
          };
          # HTTP/WS — API, oauth2, relay, websocket proxies
          netbird-backend = {
            rule = "Host(`${serverCfg.domain}`) && (PathPrefix(`/api`) || PathPrefix(`/oauth2`) || PathPrefix(`/relay`) || PathPrefix(`/ws-proxy/`))";
            service = "netbird-server";
            entryPoints = [ "websecure" ];
            tls.certResolver = "letsencrypt";
            priority = 100;
          };
          # dashboard catch-all (lowest HTTP priority)
          netbird-dashboard = {
            rule = "Host(`${serverCfg.domain}`)";
            service = "netbird-dashboard";
            entryPoints = [ "websecure" ];
            tls.certResolver = "letsencrypt";
            priority = 1;
          };
        };
        services = {
          netbird-dashboard.loadBalancer.servers = [
            { url = "http://127.0.0.1:${toString cfg.dashboardPort}"; }
          ];
          netbird-server.loadBalancer.servers = [
            { url = "http://127.0.0.1:${toString cfg.serverPort}"; }
          ];
          netbird-server-h2c.loadBalancer.servers = [
            { url = "h2c://127.0.0.1:${toString cfg.serverPort}"; }
          ];
        };
      };
      # TCP passthrough for reverse proxy (catches unmatched SNI)
      tcp = {
        routers.proxy-passthrough = {
          rule = "HostSNI(`*`)";
          entryPoints = [ "websecure" ];
          service = "proxy-tls";
          tls.passthrough = true;
          priority = 1;
        };
        services.proxy-tls.loadBalancer.servers = [
          { address = "127.0.0.1:${toString (lib.toInt (lib.removePrefix ":" cfg.addr))}"; }
        ];
      };
    };

    # --- persistence ---

    nixfiles.persistence.directories = [
      {
        directory = "/var/lib/netbird-proxy";
        user = "netbird";
        group = "netbird";
      }
    ];

  };
}
