_: {
  _class = "clan.service";
  manifest.name = "netbird";
  manifest.description = "self-hosted netbird VPN mesh with relay server and embedded IdP";
  manifest.readme = "netbird mesh VPN with management, signal, relay, and dashboard";
  manifest.categories = [ "Network" ];

  roles.server = {
    description = "runs netbird management, signal, relay, dashboard, and reverse proxy on a public VPS";
    interface =
      { lib, ... }:
      {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "public domain for netbird server (e.g. nb.fosskar.eu)";
          };
          proxyDomain = lib.mkOption {
            type = lib.types.str;
            description = "domain for the reverse proxy (e.g. proxy.fosskar.eu), services are *.proxy.fosskar.eu";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 51820;
            description = "wireguard listen port for all clients";
          };
        };
      };

    perInstance =
      {
        settings,
        ...
      }:
      {
        nixosModule =
          {
            config,
            pkgs,
            ...
          }:
          let
            relaySecretPath = config.clan.core.vars.generators.netbird-server.files."relay-secret".path;
            encryptionKeyPath = config.clan.core.vars.generators.netbird-server.files."encryption-key".path;

          in
          {
            imports = [ ../../modules/netbird ];

            # server secrets
            clan.core.vars.generators.netbird-server = {
              files."relay-secret" = { };
              files."encryption-key" = { };
              files."owner-password" = { }; # plain password — for dashboard login
              files."owner-password-hash".secret = false;

              runtimeInputs = [
                pkgs.openssl
                pkgs.apacheHttpd # for htpasswd (bcrypt)
              ];
              script = ''
                openssl rand -hex 32 | tr -d '\n' > "$out/relay-secret"
                openssl rand -base64 32 | tr -d '\n' > "$out/encryption-key"
                # generate owner password and its bcrypt hash for embedded IdP
                openssl rand -base64 24 | tr -d '\n' > "$out/owner-password"
                htpasswd -bnBC 10 "" "$(cat "$out/owner-password")" | tr -d ':\n' > "$out/owner-password-hash"

              '';
            };

            # combined server (management + signal + relay + embedded IdP)
            services.netbird.server = {
              enable = true;
              inherit (settings) domain;
              package = pkgs.custom.netbird-server;
              authSecretFile = relaySecretPath;
              encryptionKeyFile = encryptionKeyPath;
              ownerEmail = "admin@fosskar.eu";
              ownerPasswordHashFile =
                config.clan.core.vars.generators.netbird-server.files."owner-password-hash".path;
            };

            # dashboard (static files served by nginx on internal port)
            services.netbird.server.dashboard = {
              enable = true;
              inherit (settings) domain;
              package = pkgs.custom.netbird-dashboard;
              managementServer = "https://${settings.domain}";
              settings = {
                AUTH_AUTHORITY = "https://${settings.domain}/oauth2";
                AUTH_CLIENT_ID = "netbird-dashboard";
                AUTH_AUDIENCE = "netbird-dashboard";
                AUTH_SUPPORTED_SCOPES = "openid profile email";
                AUTH_REDIRECT_URI = "/nb-auth";
                AUTH_SILENT_REDIRECT_URI = "/nb-silent-auth";
                NETBIRD_TOKEN_SOURCE = "idToken";
                USE_AUTH0 = false;
              };
            };

            # serve dashboard static files on internal port (traefik in front)
            services.nginx = {
              enable = true;
              defaultHTTPListenPort = 8080;
              virtualHosts.dashboard = {
                listen = [
                  {
                    addr = "127.0.0.1";
                    port = 8080;
                  }
                ];
                root = config.services.netbird.server.dashboard.finalDrv;
                locations."/".tryFiles = "$uri $uri.html $uri/ =404";
                extraConfig = "error_page 404 /404.html;";
              };
            };

            # traefik — TLS termination for dashboard/API, TLS passthrough for proxy
            # ensure traefik state dir is writable
            systemd.services.traefik.serviceConfig.StateDirectory = "traefik";

            services.traefik = {
              enable = true;
              staticConfigOptions = {
                entryPoints = {
                  web = {
                    address = ":80";
                    http.redirections.entryPoint = {
                      to = "websecure";
                      scheme = "https";
                    };
                  };
                  websecure = {
                    address = ":443";
                    allowACMEByPass = true;
                    transport.respondingTimeouts = {
                      readTimeout = "0s";
                      writeTimeout = "0s";
                      idleTimeout = "0s";
                    };
                  };
                };
                certificatesResolvers.letsencrypt.acme = {
                  email = "letsencrypt.unpleased904@passmail.net";
                  storage = "/var/lib/traefik/acme.json";
                  tlsChallenge = { };
                };
                serversTransport.forwardingTimeouts = {
                  responseHeaderTimeout = "0s";
                  idleConnTimeout = "0s";
                };
              };
            };

            services.traefik.dynamicConfigOptions = {
              http = {
                routers = {
                  # gRPC — needs h2c backend (highest priority)
                  # gRPC — needs h2c backend (highest priority)
                  netbird-grpc = {
                    rule = "Host(`${settings.domain}`) && (PathPrefix(`/signalexchange.SignalExchange/`) || PathPrefix(`/management.ManagementService/`) || PathPrefix(`/management.ProxyService/`))";
                    service = "netbird-server-h2c";
                    entryPoints = [ "websecure" ];
                    tls.certResolver = "letsencrypt";
                    priority = 100;
                  };
                  # HTTP/WS — API, oauth2, relay, websocket proxies
                  netbird-backend = {
                    rule = "Host(`${settings.domain}`) && (PathPrefix(`/api`) || PathPrefix(`/oauth2`) || PathPrefix(`/relay`) || PathPrefix(`/ws-proxy/`))";
                    service = "netbird-server";
                    entryPoints = [ "websecure" ];
                    tls.certResolver = "letsencrypt";
                    priority = 100;
                  };
                  # dashboard catch-all (lowest HTTP priority)
                  netbird-dashboard = {
                    rule = "Host(`${settings.domain}`)";
                    service = "netbird-dashboard";
                    entryPoints = [ "websecure" ];
                    tls.certResolver = "letsencrypt";
                    priority = 1;
                  };
                };
                services = {
                  netbird-dashboard.loadBalancer.servers = [
                    { url = "http://127.0.0.1:8080"; }
                  ];
                  netbird-server.loadBalancer.servers = [
                    { url = "http://127.0.0.1:8081"; }
                  ];
                  netbird-server-h2c.loadBalancer.servers = [
                    { url = "h2c://127.0.0.1:8081"; }
                  ];
                };
              };
              # TCP passthrough for reverse proxy (lowest priority, catches unmatched SNI)
              tcp = {
                routers.proxy-passthrough = {
                  rule = "HostSNI(`*`)";
                  entryPoints = [ "websecure" ];
                  service = "proxy-tls";
                  tls.passthrough = true;
                  priority = 1;
                };
                services.proxy-tls.loadBalancer.servers = [
                  { address = "127.0.0.1:8443"; }
                ];
              };
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
                StateDirectory = "netbird-server";
              };
              script = ''
                # wait for server to be ready
                for i in $(seq 1 30); do
                  ${pkgs.curl}/bin/curl -sf http://localhost:8081/api/users >/dev/null 2>&1 && break
                  sleep 2
                done
                TOKEN=$(${pkgs.custom.netbird-server}/bin/netbird-server token create \
                  --config /var/lib/netbird-server/config.yaml \
                  --name proxy --expires-in 3650d 2>&1 | grep -oP 'nbx_\S+')
                echo -n "$TOKEN" > /var/lib/netbird-server/proxy-token
                chmod 600 /var/lib/netbird-server/proxy-token
              '';
            };

            # reverse proxy
            services.netbird.server.proxy = {
              enable = true;
              package = pkgs.custom.netbird-proxy;
              domain = settings.proxyDomain;
              managementAddress = "http://127.0.0.1:8081";
              addr = ":8443";
              tokenFile = "/var/lib/netbird-server/proxy-token";
              allowInsecure = true; # connecting over localhost
            };

            # persist state
            nixfiles.persistence.directories = [
              "/var/lib/netbird-server"
              "/var/lib/netbird-proxy"
              "/var/lib/traefik"
            ];

            # firewall
            networking.firewall.allowedTCPPorts = [
              80
              443
            ];
            networking.firewall.allowedUDPPorts = [
              3478 # STUN
            ];
          };
      };
  };

  roles.client = {
    description = "connects to the netbird mesh network";
    interface =
      { lib, ... }:
      {
        options = {
          routingFeatures = lib.mkOption {
            type = lib.types.enum [
              "none"
              "client"
              "server"
              "both"
            ];
            default = "client";
            description = ''
              "server" for routing peers (hm-nixbox), "client" for workstations that use routes
            '';
          };
        };
      };

    perInstance =
      {
        settings,
        roles,
        ...
      }:
      {
        nixosModule =
          {
            lib,
            ...
          }:
          let
            # get the server domain from the server role
            serverMachines = lib.attrNames (roles.server.machines or { });
            serverName = lib.head serverMachines;
            serverSettings = (roles.server.machines.${serverName} or { }).settings or { };
          in
          {
            services.netbird = {
              enable = true;
              useRoutingFeatures = settings.routingFeatures;
              clients.default = {
                port = serverSettings.port or 51820;
                config = {
                  ManagementURL = {
                    Scheme = "https";
                    Host = "${serverSettings.domain or "localhost"}:443";
                  };
                  AdminURL = {
                    Scheme = "https";
                    Host = "${serverSettings.domain or "localhost"}:443";
                  };
                };
              };
            };

            # persist client state
            nixfiles.persistence.directories = [
              "/var/lib/netbird"
            ];
          };
      };
  };
}
