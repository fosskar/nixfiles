{
  flake.modules.nixos.netbirdServerStack =
    # netbird reverse proxy: traefik routes + nginx dashboard + proxy service; requires modules/traefik
    {
      config,
      lib,
      pkgs,
      options,
      ...
    }:

    let
      cfg = config.services.netbird.server.proxy;
      serverCfg = config.services.netbird.server;
      stateDir = "/var/lib/netbird-proxy";
      # root-only, so no service uid can swap a credential source for a symlink
      credentialsDir = "/var/lib/netbird-proxy-credentials";
      configFile =
        (pkgs.formats.yaml { }).generate "crowdsec.yaml"
          config.services.crowdsec.settings.general;
      inherit (cfg.crowdsec) apiKeyFile;
      tcpPorts = lib.concatMapStringsSep ", " toString ([ 443 ] ++ cfg.publicTCPPorts);
      bouncerName = "netbird-proxy";
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

        logLevel = lib.mkOption {
          type = lib.types.enum [
            "panic"
            "fatal"
            "error"
            "warn"
            "info"
            "debug"
            "trace"
          ];
          default = "info";
          description = "proxy log level";
        };

        tokenFile = lib.mkOption {
          type = lib.types.str;
          default = "${credentialsDir}/proxy-token";
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

        publicTCPPorts = lib.mkOption {
          type = lib.types.listOf lib.types.port;
          default = [ ];
          description = "additional public tcp ports exposed by netbird tcp services";
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

        serverPort = lib.mkOption {
          type = lib.types.port;
          default = 8081;
          description = "internal port where netbird-server listens";
        };

        crowdsec = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "enable built-in crowdsec IP reputation stream bouncer (netbird >= 0.69.0)";
          };
          apiURL = lib.mkOption {
            type = lib.types.str;
            default = "http://127.0.0.1:8085";
            description = "crowdsec LAPI URL";
          };
          apiKeyFile = lib.mkOption {
            type = lib.types.str;
            default = config.clan.core.vars.generators.netbird-proxy-crowdsec.files.api-key.path;
            description = "path to file containing the bouncer API key";
          };
        };

      };

      config = lib.mkIf cfg.enable (
        {

          services.netbird.server.proxy.logLevel = lib.mkIf cfg.crowdsec.enable (lib.mkDefault "debug");

          networking.firewall.allowedTCPPorts = cfg.publicTCPPorts;

          services.crowdsec.localConfig.acquisitions = lib.mkIf cfg.crowdsec.enable [
            {
              source = "journalctl";
              journalctl_filter = [ "_SYSTEMD_UNIT=netbird-proxy.service" ];
              labels.type = "netbird-proxy";
            }
          ];

          # --- systemd ---

          systemd.services.crowdsec-netbird-proxy-bouncer-register = lib.mkIf cfg.crowdsec.enable {
            description = "register crowdsec netbird-proxy bouncer";
            wantedBy = [ "multi-user.target" ];
            before = [ "netbird-proxy.service" ];
            after = [ "crowdsec.service" ];
            wants = [ "crowdsec.service" ];
            # the key comes from vars, so re-registering with it is idempotent
            script = ''
              cscli=${lib.getExe' config.services.crowdsec.package "cscli"}
              if $cscli -c ${configFile} bouncers list --output json | ${lib.getExe pkgs.jq} -e -- ${lib.escapeShellArg "any(.[]; .name == \"${bouncerName}\")"} >/dev/null; then
                $cscli -c ${configFile} bouncers delete ${lib.escapeShellArg bouncerName}
              fi
              $cscli -c ${configFile} bouncers add --key "$(cat "$CREDENTIALS_DIRECTORY/api-key")" -- ${lib.escapeShellArg bouncerName} >/dev/null
            '';
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              User = config.services.crowdsec.user;
              Group = config.services.crowdsec.group;
              ReadWritePaths = [ "/var/lib/crowdsec" ];
              LoadCredential = [ "api-key:${apiKeyFile}" ];
              LockPersonality = true;
              PrivateDevices = true;
              ProcSubset = "pid";
              ProtectClock = true;
              ProtectControlGroups = true;
              ProtectHome = true;
              ProtectHostname = true;
              ProtectKernelLogs = true;
              ProtectKernelModules = true;
              ProtectKernelTunables = true;
              ProtectProc = "invisible";
              RestrictNamespaces = true;
              RestrictRealtime = true;
              SystemCallArchitectures = "native";
              RestrictAddressFamilies = "none";
              CapabilityBoundingSet = [ "" ];
              SystemCallFilter = [
                "@system-service"
                "~@privileged"
                "~@resources"
              ];
              UMask = "0077";
            };
          };

          # order traefik after proxy to avoid boot-time "connection refused 127.0.0.1:8443" spam
          systemd.services.traefik = lib.mkIf config.services.traefik.enable {
            after = [ "netbird-proxy.service" ];
            wants = [ "netbird-proxy.service" ];
          };

          systemd.services.netbird-proxy = {
            description = "netbird reverse proxy";
            documentation = [ "https://docs.netbird.io/manage/reverse-proxy" ];
            after = [
              "network.target"
              "netbird-server.service"
              "netbird-proxy-token.service"
            ]
            ++ lib.optional cfg.crowdsec.enable "crowdsec-netbird-proxy-bouncer-register.service";
            requires = [
              "netbird-proxy-token.service"
            ]
            ++ lib.optional cfg.crowdsec.enable "crowdsec-netbird-proxy-bouncer-register.service";
            wantedBy = [ "multi-user.target" ];

            environment = {
              NB_PROXY_LOG_LEVEL = cfg.logLevel;
              NB_PROXY_DOMAIN = cfg.domain;
              NB_PROXY_MANAGEMENT_ADDRESS = cfg.managementAddress;
              NB_PROXY_ADDRESS = cfg.addr;
              NB_PROXY_CERTIFICATE_DIRECTORY = cfg.certDir;
              NB_PROXY_ACME_CERTIFICATES = lib.boolToString cfg.acmeCerts;
              NB_PROXY_ACME_CHALLENGE_TYPE = cfg.acmeChallengeType;
              NB_PROXY_HEALTH_ADDRESS = "localhost:8444";
              NB_PROXY_DEBUG_ENDPOINT_ADDRESS = "localhost:8445";
              NB_PROXY_GEO_DATA_DIR = "${stateDir}/geolocation";
              # embedded client default state dir /var/lib/netbird is root-owned; redirect
              NB_STATE_DIR = stateDir;
              # PROXY protocol v2 from traefik passthrough: real client IPs in events
              NB_PROXY_PROXY_PROTOCOL = "true";
              NB_PROXY_TRUSTED_PROXIES = "127.0.0.1/32";
              # capability flag: allows per-service NetBird-Only access mode
              NB_PROXY_PRIVATE = "true";
            }
            // lib.optionalAttrs cfg.allowInsecure {
              NB_PROXY_ALLOW_INSECURE = "true";
            }
            // lib.optionalAttrs cfg.crowdsec.enable {
              NB_PROXY_CROWDSEC_API_URL = cfg.crowdsec.apiURL;
            };

            script = ''
              NB_PROXY_TOKEN=$(cat "$CREDENTIALS_DIRECTORY/proxy-token")
              export NB_PROXY_TOKEN
              ${lib.optionalString cfg.crowdsec.enable ''
                NB_PROXY_CROWDSEC_API_KEY=$(cat "$CREDENTIALS_DIRECTORY/crowdsec-api-key")
                export NB_PROXY_CROWDSEC_API_KEY
              ''}
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
              LoadCredential = [
                "proxy-token:${cfg.tokenFile}"
              ]
              ++ lib.optional cfg.crowdsec.enable "crowdsec-api-key:${cfg.crowdsec.apiKeyFile}";

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
              # not netbird: the internet-facing proxy must not read netbird-server state
              User = "netbird-proxy";
              Group = "netbird-proxy";
            };

            stopIfChanged = false;
          };

          users.users.netbird-proxy = {
            isSystemUser = true;
            group = "netbird-proxy";
          };
          users.groups.netbird-proxy = { };

          systemd.tmpfiles.rules = [ "d ${credentialsDir} 0700 root root -" ];

          clan.core.vars.generators.netbird-proxy-crowdsec = lib.mkIf cfg.crowdsec.enable {
            files.api-key = { };
            runtimeInputs = [ pkgs.openssl ];
            script = ''
              openssl rand -hex 32 | tr -d '\n' > "$out/api-key"
            '';
          };

          # generate proxy access token on first boot
          systemd.services.netbird-proxy-token = {
            description = "generate netbird proxy access token";
            after = [ "netbird-server.service" ];
            requires = [ "netbird-server.service" ];
            wantedBy = [ "multi-user.target" ];
            unitConfig.ConditionFileNotEmpty = "!${cfg.tokenFile}";
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              User = "netbird";
              Group = "netbird";
              StateDirectory = "netbird-server";
              UMask = "0077";
              # pid1 writes the token into the root-only directory; the script
              # prints nothing else on stdout
              StandardOutput = "truncate:${cfg.tokenFile}";
            };
            script = ''
              # wait for server to be ready; /api/instance answers without auth
              ready=0
              for _ in $(seq 1 30); do
                if ${pkgs.curl}/bin/curl -sf http://localhost:${toString cfg.serverPort}/api/instance >/dev/null 2>&1; then
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
              if [ -z "$TOKEN" ]; then
                echo "failed to create netbird proxy token" >&2
                exit 1
              fi
              printf '%s' "$TOKEN"
            '';
          };

          # parse debug-level `response:` journal lines into http_access-log shape for stock http-* scenarios
          services.crowdsec.localConfig.parsers.s01Parse = lib.mkIf cfg.crowdsec.enable [
            {
              onsuccess = "next_stage";
              filter = "evt.Line.Labels.type == 'netbird-proxy'";
              name = "nixfiles/netbird-proxy-logs";
              description = "parse netbird-proxy access log debug lines";
              nodes = [
                {
                  grok = {
                    pattern = "%{TIMESTAMP_ISO8601} DEBG %{DATA}middleware.go:%{NUMBER}: response: request_id=%{DATA:request_id} method=%{WORD:method} host=%{HOSTNAME:host} path=%{NOTSPACE:path} status=%{INT:status} duration=%{NOTSPACE:duration} source=%{IP:source_ip} origin=%{DATA:origin} service=%{DATA:service_id} account=%{NOTSPACE:account_id}$";
                    apply_on = "Line.Raw";
                  };
                  statics = [
                    {
                      meta = "log_type";
                      value = "http_access-log";
                    }
                    {
                      meta = "source_ip";
                      expression = "evt.Parsed.source_ip";
                    }
                    {
                      meta = "http_status";
                      expression = "evt.Parsed.status";
                    }
                    {
                      meta = "http_path";
                      expression = "evt.Parsed.path";
                    }
                    {
                      meta = "http_verb";
                      expression = "evt.Parsed.method";
                    }
                    {
                      meta = "http_hostname";
                      expression = "evt.Parsed.host";
                    }
                    {
                      meta = "http_user_agent";
                      value = "-";
                    }
                    {
                      meta = "service";
                      value = "http";
                    }
                    {
                      parsed = "program";
                      value = "netbird-proxy";
                    }
                  ];
                }
              ];
            }
          ];

          # signal and management.ProxyService are bidirectional grpc streams: a
          # nonzero readTimeout cuts their request body. traefik has no
          # header-only timeout, so connections that never send a byte are held
          # forever; traefik-connlimit bounds that per source address
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

          # busiest legitimate source held 14 connections in 2026-09
          networking.nftables.tables.traefik-connlimit = {
            family = "inet";
            content = ''
              set conn4 { type ipv4_addr; flags dynamic; size 65535; }
              set conn6 { type ipv6_addr; flags dynamic; size 65535; }
              set quic4 { type ipv4_addr; flags dynamic; size 65535; }
              set quic6 { type ipv6_addr; flags dynamic; size 65535; }
              chain input {
                type filter hook input priority filter - 1; policy accept;
                tcp dport { ${tcpPorts} } ct state new add @conn4 { ip saddr ct count over 128 } counter reject with tcp reset
                tcp dport { ${tcpPorts} } ct state new add @conn6 { ip6 saddr and ffff:ffff:ffff:ffff:: ct count over 128 } counter reject with tcp reset
                udp dport 443 ct state new add @quic4 { ip saddr ct count over 128 } counter drop
                udp dport 443 ct state new add @quic6 { ip6 saddr and ffff:ffff:ffff:ffff:: ct count over 128 } counter drop
              }
            '';
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
                # dashboard catch-all lives in dashboard.nix (can route via anubis)
              };
              services = {
                # dashboard service lives in dashboard.nix, same as the router
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
              services.proxy-tls.loadBalancer = {
                proxyProtocol.version = 2;
                servers = [
                  { address = "127.0.0.1:${toString (lib.toInt (lib.removePrefix ":" cfg.addr))}"; }
                ];
              };
            };
          };

        }
        // lib.optionalAttrs (options ? preservation) {
          # --- persistence ---
          preservation.preserveAt."/persist".directories = [
            {
              directory = "/var/lib/netbird-proxy";
              user = "netbird-proxy";
              group = "netbird-proxy";
            }
            {
              directory = credentialsDir;
              mode = "0700";
            }
          ];
        }
      );
    };
}
