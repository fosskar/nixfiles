{ self, ... }:
{
  flake.modules."clan.service".hermes =
    _:
    let
      # hermes provider name -> fencr credential provider preset
      fencrProviders = {
        anthropic = "anthropic";
        openai = "openai";
        openrouter = "openrouter";
        opencode_go = "opencode";
      };
      webappPort = 9120;
      webappHost = instanceName: "${instanceName}.${self.domains.local}";
    in
    {

      manifest.name = "hermes";
      manifest.description = "Hermes agent server and its webapp";
      manifest.readme = builtins.readFile ./README.md;
      manifest.categories = [ "Utility" ];

      roles.server = {
        description = "Run Hermes in a fencr sandbox and serve its webapp";

        interface =
          { lib, ... }:
          {
            options = {
              webapp.enable = lib.mkEnableOption "the Hermes webapp at https://<instance>.<local domain>, behind authelia oidc";

              mcp.allow = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                example = [ "calendar.*" ];
                description = "gateway tools this agent may use, as <server>.<tool> globs; empty leaves it without the gateway. needs self.modules.nixos.mcp on the server.";
              };

              soul = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "key into flake.llm.souls, the starting SOUL.md; the agent may change it afterwards.";
              };

              agentSettings = lib.mkOption {
                type = lib.types.attrsOf lib.types.raw;
                default = { };
                description = "merged into services.hermes-agent.managed.settings: model, providers, tts, plugins, ...";
              };

              skills = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "keys into flake.llm.skills.";
              };

              catalogPlugins = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "hermes plugin-catalog entries to install and enable, by catalog name.";
              };

              packageSkills = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "skill dirs relative to the hermes package's share/hermes-agent.";
              };

              providers = lib.mkOption {
                type = lib.types.attrsOf (
                  lib.types.submodule {
                    options.enable = lib.mkEnableOption "this provider";
                  }
                );
                default = { };
                description = "local is the keyless homelab llama-cpp endpoint; any other enabled provider prompts for <NAME>_API_KEY.";
              };

              matrix = {
                enable = lib.mkEnableOption "the matrix channel";
                homeserver = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                userId = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  example = "@hermes:example.org";
                };
                allowedUsers = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                };
                deviceId = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                homeChannel = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
              };

              signal.enable = lib.mkEnableOption "the signal channel";

              telegram = {
                enable = lib.mkEnableOption "the telegram channel";
                allowedUsers = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "numeric telegram user ids allowed to talk to the agent.";
                };
              };

              computerUse.enable = lib.mkEnableOption "background desktop control on a headless X display";

              mnemosyne.enable = lib.mkEnableOption "mnemosyne, a local sqlite memory provider with vector recall";

              fastModel = lib.mkOption {
                type = lib.types.nullOr (lib.types.attrsOf lib.types.str);
                default = null;
                example = {
                  provider = "opencode-go";
                  model = "glm-5.3-flash";
                };
                description = "small model for helper calls and a fast subagent route.";
              };

              buzz = {
                enable = lib.mkEnableOption "the buzz channel";
                channels = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "channel UUIDs to watch; empty = all joined channels.";
                };
                homeChannel = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                allowedUsers = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "npubs or hex pubkeys allowed to talk to the agent.";
                };
                replyInThread = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "thread replies under the triggering message; false posts flat to the channel.";
                };
              };

              homeAssistant = {
                enable = lib.mkEnableOption "the home assistant integration";
                address = lib.mkOption {
                  type = lib.types.str;
                  default = "192.168.10.50";
                  description = "home assistant IPv4 address used in the agent's URL.";
                };
                port = lib.mkOption {
                  type = lib.types.port;
                  default = 8123;
                };
              };
            };
          };

        perInstance =
          {
            instanceName,
            settings,
            ...
          }:
          {
            nixosModule =
              {
                config,
                lib,
                ...
              }:
              let
                generator = "${instanceName}-agent";
                generators = config.clan.core.vars.generators;
                sandbox = config.fencr.sandboxes.${instanceName};
                sandboxHost = "${instanceName}.fencr";
                webHost = webappHost instanceName;
                oidcClientId = "hermes-${instanceName}";
                credentialName = provider: "${instanceName}-${provider}";
                mcp = settings.mcp.allow != [ ];
                localProvider = settings.providers.local.enable or false;
                keyProviders = lib.attrNames (
                  lib.filterAttrs (name: provider: provider.enable && name != "local") settings.providers
                );

                # one entry per channel: the feature modules it brings, the operator
                # prompts it needs, and the .env variables fed from those prompts.
                # enabling a channel cannot leave one of them behind
                channels = {
                  matrix = {
                    enable = settings.matrix.enable;
                    modules = [
                      self.modules.nixos.hermesMatrix
                      {
                        services.hermes-agent.matrix = {
                          inherit (settings.matrix) userId allowedUsers;
                        }
                        // lib.optionalAttrs (settings.matrix.homeserver != null) {
                          inherit (settings.matrix) homeserver;
                        }
                        // lib.optionalAttrs (settings.matrix.deviceId != null) {
                          inherit (settings.matrix) deviceId;
                        }
                        // lib.optionalAttrs (settings.matrix.homeChannel != null) {
                          inherit (settings.matrix) homeChannel;
                        };
                      }
                    ];
                    prompts = {
                      matrix-access-token = "Matrix access token for ${settings.matrix.userId}";
                      matrix-recovery-key = "Matrix recovery key for ${settings.matrix.userId}";
                    };
                    env = {
                      MATRIX_ACCESS_TOKEN = "matrix-access-token";
                      MATRIX_RECOVERY_KEY = "matrix-recovery-key";
                    };
                  };

                  signal = {
                    enable = settings.signal.enable;
                    modules = [ self.modules.nixos.hermesSignal ];
                    prompts.signal-account-number = "Signal account phone number in E.164 format";
                    env = {
                      SIGNAL_ACCOUNT = "signal-account-number";
                      SIGNAL_ALLOWED_USERS = "signal-account-number";
                    };
                  };

                  buzz = {
                    enable = settings.buzz.enable;
                    modules = [
                      self.modules.nixos.hermesBuzz
                      {
                        services.hermes-agent.buzz = {
                          inherit (settings.buzz) channels allowedUsers replyInThread;
                        }
                        // lib.optionalAttrs (settings.buzz.homeChannel != null) {
                          inherit (settings.buzz) homeChannel;
                        };
                      }
                    ];
                    prompts.buzz-private-key = "Nostr private key (nsec or hex) for the agent's buzz identity";
                    env.BUZZ_PRIVATE_KEY = "buzz-private-key";
                  };

                  telegram = {
                    enable = settings.telegram.enable;
                    modules = [
                      self.modules.nixos.hermesTelegram
                      {
                        services.hermes-agent.managed.environment.TELEGRAM_ALLOWED_USERS =
                          lib.concatStringsSep "," settings.telegram.allowedUsers;
                      }
                    ];
                    prompts.telegram-bot-token = "Telegram bot token from @BotFather";
                    env.TELEGRAM_BOT_TOKEN = "telegram-bot-token";
                  };

                  homeAssistant = {
                    enable = settings.homeAssistant.enable;
                    modules = [
                      self.modules.nixos.hermesHomeAssistant
                      {
                        services.hermes-agent.homeAssistant.url = "http://${settings.homeAssistant.address}:${toString settings.homeAssistant.port}";
                      }
                    ];
                    prompts.home-assistant-token = "Home Assistant long-lived access token for the agent";
                    env.HASS_TOKEN = "home-assistant-token";
                  };
                };

                active = lib.attrValues (lib.filterAttrs (_: channel: channel.enable) channels);
                mergeAttrsOf = field: lib.foldl' (acc: channel: acc // channel.${field} or { }) { } active;
                hiddenPrompt = description: {
                  description = "${instanceName}: ${description}";
                  type = "hidden";
                  persist = true;
                };
              in
              {
                imports = [ self.modules.nixos.fencr ];

                options.nixfiles.hermes.${instanceName} = {
                  webapp.enable = lib.mkOption {
                    type = lib.types.bool;
                    readOnly = true;
                    description = "whether this instance serves the webapp.";
                  };
                  module = lib.mkOption {
                    type = lib.types.deferredModule;
                    readOnly = true;
                    description = "Hermes application module for host composition.";
                  };
                };

                config = {
                  networking.hosts.${sandbox.ip} = [ sandboxHost ];
                  fencr.sandboxes.${instanceName} = {
                    services = [
                      config.nixfiles.hermes.${instanceName}.module
                      (
                        { agentSandbox, ... }:
                        {
                          # profiles (bots) read provider keys only from their own .env;
                          # the managed .env reaches every profile. fencr's placeholders
                          # are no secret and only work through its proxy
                          services.hermes-agent.managed.environment = agentSandbox.credentialEnv;
                          services.hermes-agent.managed.settings.mcp_servers = lib.mkIf mcp {
                            fencr-gateway.url = agentSandbox.mcp.url;
                          };
                          # the gateway serves the webapp on the guest address (plus a
                          # loopback twin); the host's caddy proxies to it over fencr inbound
                          services.hermes-agent.managed.settings.webapp = lib.mkIf settings.webapp.enable {
                            enabled = true;
                            host = agentSandbox.ip;
                            port = webappPort;
                            public_url = "https://${webHost}";
                          };
                          services.hermes-agent.managed.settings.dashboard = lib.mkIf settings.webapp.enable {
                            trusted_proxies = [ agentSandbox.hostIp ];
                            # public pkce client; the sign-in gate is mandatory off loopback
                            oauth.self_hosted = {
                              issuer = "https://auth.${self.domains.public}";
                              client_id = oidcClientId;
                              # without a refresh token the session ends with the id token (1 h)
                              scopes = "openid profile email offline_access";
                            };
                          };
                          systemd.services.hermes-agent.serviceConfig.EnvironmentFile =
                            "/run/agent-secrets/${instanceName}.env";
                        }
                      )
                    ];
                    specialArgs = {
                      inherit self;
                      inherit (self) inputs;
                      flake-self = self;
                    };
                    inbound = lib.optional settings.webapp.enable webappPort;
                    outbound = [
                      "internet"
                      # *.nx3.eu (search, llama-cpp) is nixbox's caddy; fencr reaches
                      # the host's own addresses only through host:<port>
                      (if config.networking.hostName == "nixbox" then "host:443" else "${self.hosts.nixbox.lan}:443")
                    ]
                    ++ lib.optional settings.homeAssistant.enable "${settings.homeAssistant.address}:${toString settings.homeAssistant.port}";
                    mcp = {
                      enable = mcp;
                      inherit (settings.mcp) allow;
                    };
                    credentials = map credentialName keyProviders;
                    secrets = {
                      "${instanceName}.env" = generators.${generator}.files.".env".path;
                    };
                  };

                  # the proxy sets the real header for the provider's domain;
                  # guestEnv hands the sandbox a placeholder so hermes accepts the
                  # provider without a key
                  fencr.credentials = lib.listToAttrs (
                    map (provider: {
                      name = credentialName provider;
                      value = {
                        provider =
                          fencrProviders.${provider}
                            or (throw "hermes: no fencr credential provider for ${provider}; extend fencrProviders");
                        secretFile = generators.${generator}.files."${provider}-authorization".path;
                        guestEnv = "${lib.toUpper provider}_API_KEY";
                      };
                    }) keyProviders
                  );

                  nixfiles.hermes.${instanceName} = {
                    webapp.enable = settings.webapp.enable;
                    module = {
                      imports = [
                        self.modules.nixos.hermesAgent

                        (
                          { config, flake-self, ... }:
                          {
                            services.hermes-agent = {
                              localProvider.enable = localProvider;
                              inherit (settings) fastModel;

                              skillDirs =
                                map (
                                  dir: "${config.services.hermes-agent.package}/share/hermes-agent/${dir}"
                                ) settings.packageSkills
                                ++ map (name: "${flake-self.llm.skills.${name}}") settings.skills;

                              inherit (settings) catalogPlugins;

                              overrides = settings.agentSettings;

                              soul = if settings.soul == null then null else flake-self.llm.souls.${settings.soul};
                            };
                          }
                        )
                      ]
                      ++ lib.optional settings.computerUse.enable self.modules.nixos.hermesComputerUse
                      ++ lib.optional settings.mnemosyne.enable self.modules.nixos.hermesMnemosyne
                      ++ lib.concatMap (channel: channel.modules) active;
                    };
                  };

                  services.caddy.virtualHosts.${webHost}.extraConfig = lib.mkIf settings.webapp.enable ''
                    reverse_proxy ${sandbox.ip}:${toString webappPort}
                  '';

                  # one agent per person: only members of the ldap group named after
                  # the instance sign in, since every account acts as the agent's owner
                  services.authelia.instances.main.settings.identity_providers.oidc.authorization_policies.${oidcClientId} =
                    lib.mkIf settings.webapp.enable {
                      default_policy = "deny";
                      rules = [
                        {
                          policy = "two_factor";
                          subject = [ "group:${instanceName}" ];
                        }
                      ];
                    };

                  # each refresh issues a new refresh token, so a week only ends an idle login,
                  # as the authelia session does
                  services.authelia.instances.main.settings.identity_providers.oidc.lifespans.custom.${oidcClientId} =
                    lib.mkIf settings.webapp.enable
                      {
                        refresh_token = "1w";
                      };

                  services.authelia.instances.main.settings.identity_providers.oidc.clients =
                    lib.mkIf settings.webapp.enable
                      [
                        {
                          client_id = oidcClientId;
                          client_name = "Hermes ${instanceName}";
                          public = true;
                          consent_mode = "implicit";
                          authorization_policy = oidcClientId;
                          redirect_uris = [ "https://${webHost}/auth/callback" ];
                          scopes = [
                            "openid"
                            "profile"
                            "email"
                            "offline_access"
                          ];
                          require_pkce = true;
                          pkce_challenge_method = "S256";
                          response_types = [ "code" ];
                          grant_types = [
                            "authorization_code"
                            "refresh_token"
                          ];
                          lifespan = oidcClientId;
                          token_endpoint_auth_method = "none";
                        }
                      ];

                  services.homepage-dashboard.services = lib.mkIf settings.webapp.enable [
                    {
                      "llm" = [
                        {
                          "Hermes ${instanceName}" = {
                            href = "https://${webHost}";
                            icon = "mdi-robot-outline";
                          };
                        }
                      ];
                    }
                  ];

                  services.gatus.settings.endpoints = lib.mkIf settings.webapp.enable [
                    {
                      name = "Hermes ${instanceName}";
                      url = "https://${webHost}";
                      enabled = true;
                      alerts = [ { type = "matrix"; } ];
                      interval = "5m";
                      conditions = [ "[STATUS] == 200" ];
                    }
                  ];

                  clan.core.vars.generators.${generator} = {
                    files = {
                      ".env" = {
                        secret = true;
                        # the guest fetches raw secrets once per boot; a new value needs a new boot
                        restartUnits = [ "fencr-${instanceName}.service" ];
                      };
                    }
                    // lib.genAttrs (map (provider: "${provider}-authorization") keyProviders) (_: {
                      secret = true;
                    });

                    prompts =
                      lib.mapAttrs (_: hiddenPrompt) (mergeAttrsOf "prompts")
                      // lib.listToAttrs (
                        map (provider: {
                          name = "${provider}-api-key";
                          value = hiddenPrompt "${provider} API key";
                        }) keyProviders
                      );

                    script =
                      let
                        lines = lib.mapAttrsToList (variable: prompt: ''echo "${variable}=$(cat "$prompts/${prompt}")"'') (
                          mergeAttrsOf "env"
                        );
                        authorizations = map (
                          provider:
                          ''printf 'Bearer %s' "$(cat "$prompts/${provider}-api-key")" > "$out/${provider}-authorization"''
                        ) keyProviders;
                      in
                      ''
                        # never empty: clan opens the sops editor for an empty secret
                        {
                          echo "# hermes channel secrets"
                          ${lib.concatStringsSep "\n  " lines}
                        } > "$out/.env"
                        ${lib.concatStringsSep "\n" authorizations}
                      '';
                  };
                };
              };
          };
      };
    };
}
