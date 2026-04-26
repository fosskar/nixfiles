{ self }:
{
  clanLib,
  config,
  lib,
  ...
}:
{
  _class = "clan.service";
  manifest.name = "netbird";
  manifest.description = "self-hosted netbird VPN mesh with relay server and embedded IdP";
  manifest.readme = "netbird mesh VPN with management, signal, relay, and dashboard";
  manifest.categories = [ "Network" ];
  manifest.exports.out = [
    "networking"
    "peer"
  ];

  exports = lib.mapAttrs' (instanceName: _: {
    name = clanLib.buildScopeKey {
      inherit instanceName;
      serviceName = config.manifest.name;
    };
    value.networking.priority = 900;
  }) config.instances;

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
            imports = [ self.modules.nixos.netbird ];

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

            # dashboard
            services.netbird.server.dashboard = {
              enable = true;
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

            # reverse proxy + traefik frontend
            services.netbird.server.proxy = {
              enable = true;
              package = pkgs.custom.netbird-proxy;
              domain = settings.proxyDomain;
              managementAddress = "http://127.0.0.1:8081";
              addr = ":8443";
              tokenFile = "/var/lib/netbird-server/proxy-token";
              allowInsecure = true; # connecting over localhost
            };
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
              "server" for routing peers (nixbox), "client" for workstations that use routes
            '';
          };
        };
      };

    perInstance =
      {
        settings,
        roles,
        machine,
        mkExports,
        ...
      }:
      let
        # get the server domain from the server role
        serverMachines = lib.attrNames (roles.server.machines or { });
        serverName = lib.head serverMachines;
        serverSettings = (roles.server.machines.${serverName} or { }).settings or { };
        isServerMachine = builtins.elem machine.name serverMachines;
      in
      {
        exports = mkExports {
          peer.hosts = [
            { plain = "${machine.name}.${serverSettings.domain}"; }
          ];
        };

        nixosModule =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          {
            imports = [ self.modules.nixos.netbirdPersistence ];

            config = {
              # setup key secret
              clan.core.vars.generators.netbird-client = {
                # shared setup key across clients
                share = true;
                files."setup-key" = { };
                prompts.setup-key = {
                  description = "netbird setup key for this machine (dashboard setup-keys)";
                  type = "hidden";
                };
                script = ''
                  cp "$prompts/setup-key" "$out/setup-key"
                '';
              };

              services.netbird = {
                enable = true;
                ui.enable = false;
                package = pkgs.custom.netbird-client;
                useRoutingFeatures = settings.routingFeatures;
                clients.default = {
                  port = serverSettings.port or 51820;
                  # netbird >=0.66 logs profile-manager warnings without HOME/XDG
                  environment = {
                    HOME = "/var/lib/netbird";
                    XDG_CONFIG_HOME = "/var/lib/netbird";
                  };
                  login = {
                    enable = true;
                    setupKeyFile = config.clan.core.vars.generators.netbird-client.files."setup-key".path;
                  };
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

              # the login script already checks NeedsLogin status before acting,
              # so the state.json guard is unnecessary and prevents re-auth on expired sessions
              systemd.services.netbird-login = {
                after = lib.optionals isServerMachine [
                  "netbird-server.service"
                ];
                wants = lib.optionals isServerMachine [
                  "netbird-server.service"
                ];
                unitConfig = {
                  ConditionPathExists = lib.mkForce [ ];
                  StartLimitIntervalSec = 0;
                };
                serviceConfig = {
                  Restart = "on-failure";
                  RestartSec = "10s";
                };
                environment = {
                  HOME = "/var/lib/netbird";
                  XDG_CONFIG_HOME = "/var/lib/netbird";
                };
              };

              # trust netbird interface — netbird handles access control
              networking.firewall.trustedInterfaces = [ "wt0" ];

            };
          };
      };
  };
}
