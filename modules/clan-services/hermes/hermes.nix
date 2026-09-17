{ self, ... }:
{
  flake.modules."clan.service".hermes =
    { clanLib, ... }:
    let
      remoteKeyGenerator = instanceName: "${instanceName}-hermes-remote-ssh";
      remoteUser = instanceName: "hermes-remote-${instanceName}";
      # hermes provider name -> fencr credential provider preset
      fencrProviders = {
        anthropic = "anthropic";
        openai = "openai";
        openrouter = "openrouter";
        opencode_go = "opencode-go";
      };
      # the hermes dashboard binds loopback only; fencr forwards guest ports
      # bound on the bridge address
      dashboardGuestPort = 9119;
    in
    {

      manifest.name = "hermes";
      manifest.description = "Hermes agent server and remote desktop clients";
      manifest.readme = builtins.readFile ./README.md;
      manifest.categories = [ "AI" ];
      manifest.exports.inputs = [
        "peer"
        "networking"
      ];

      roles.server = {
        description = "Configure Hermes and its remote desktop endpoint";

        interface =
          { lib, ... }:
          {
            options = {
              dashboard.enable = lib.mkEnableOption "the Hermes dashboard and remote desktop access";

              mcp.allow = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                example = [ "calendar.*" ];
                description = "gateway tools this agent may use, as <server>.<tool> globs; empty leaves it without the gateway. needs self.modules.nixos.mcp on the server.";
              };

              soul = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "key into flake.llm.souls, installed declaratively as SOUL.md.";
              };

              agentSettings = lib.mkOption {
                type = lib.types.attrsOf lib.types.raw;
                default = { };
                description = "merged into services.hermes-agent.settings: model, providers, tts, plugins, ...";
              };

              skills = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "keys into flake.llm.skills.";
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

              computerUse.enable = lib.mkEnableOption "background desktop control on a headless X display";

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
                pkgs,
                ...
              }:
              let
                generator = "${instanceName}-agent";
                generators = config.clan.core.vars.generators;
                sshUser = remoteUser instanceName;
                vm = config.fencr.vms.${instanceName};
                vmHost = "${instanceName}.fencr";
                dashboardAddress = "${vmHost}:${toString dashboardGuestPort}";
                credentialName = provider: "${instanceName}-${provider}";
                mcp = settings.mcp.allow != [ ];
                remotePublicKey = lib.trim (
                  clanLib.getPublicValue {
                    flake = config.clan.core.settings.directory;
                    generator = remoteKeyGenerator instanceName;
                    file = "id_ed25519.pub";
                    default = "";
                  }
                );
                tokenCommand = pkgs.writeShellScript "${instanceName}-hermes-token" ''
                  if [ "''${SSH_ORIGINAL_COMMAND-}" != hermes-token ]; then
                    exit 1
                  fi
                  exec ${pkgs.coreutils}/bin/cat /run/secrets/vars/per-machine/${config.networking.hostName}/${instanceName}-dashboard/token
                '';
                localProvider = settings.providers.local.enable or false;
                keyProviders = lib.attrNames (
                  lib.filterAttrs (name: provider: provider.enable && name != "local") settings.providers
                );

                # one entry per channel: the aspect modules it brings, the operator
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
                  inherit description;
                  type = "hidden";
                  persist = true;
                };
              in
              {
                imports = [ self.modules.nixos.fencr ];

                options.nixfiles.hermes.${instanceName} = {
                  dashboard.enable = lib.mkOption {
                    type = lib.types.bool;
                    readOnly = true;
                    description = "whether this instance provides dashboard access.";
                  };
                  module = lib.mkOption {
                    type = lib.types.deferredModule;
                    readOnly = true;
                    description = "Hermes application module for host composition.";
                  };
                };

                config = {
                  networking.hosts.${vm.ip} = [ vmHost ];
                  # the build sandbox lacks this runtime account; only the check uses root.
                  networking.nftables.preCheckRuleset = lib.mkIf settings.dashboard.enable ''
                    substituteInPlace ruleset.conf \
                      --replace-fail 'meta skuid != "${sshUser}"' 'meta skuid != 0'
                  '';
                  networking.nftables.tables."${instanceName}-dashboard" = lib.mkIf settings.dashboard.enable {
                    family = "inet";
                    content = ''
                      chain output {
                        type filter hook output priority filter - 2; policy accept;
                        ip daddr ${vm.ip} tcp dport ${toString dashboardGuestPort} meta skuid != "${sshUser}" counter drop
                      }
                    '';
                  };

                  fencr.vms.${instanceName} = {
                    services = [
                      config.nixfiles.hermes.${instanceName}.module
                      {
                        services.hermes-agent.settings.mcp_servers.gateway = lib.mkIf mcp {
                          url = "https://mcp.fencr/mcp/";
                        };
                        services.hermes-agent.dashboardTokenFile = lib.mkIf settings.dashboard.enable "/run/agent-secrets/${instanceName}-dashboard-token";
                        systemd.services = {
                          hermes-agent.serviceConfig.EnvironmentFile = "/run/agent-secrets/${instanceName}.env";
                          hermes-dashboard = lib.mkIf settings.dashboard.enable {
                            serviceConfig.EnvironmentFile = "/run/agent-secrets/${instanceName}.env";
                          };
                          hermes-dashboard-relay = lib.mkIf settings.dashboard.enable {
                            description = "Hermes dashboard on the guest address";
                            wantedBy = [ "multi-user.target" ];
                            after = [ "network-online.target" ];
                            wants = [ "network-online.target" ];
                            serviceConfig = {
                              DynamicUser = true;
                              ExecStart = "${pkgs.socat}/bin/socat TCP4-LISTEN:${toString dashboardGuestPort},bind=${vm.ip},fork,reuseaddr TCP:127.0.0.1:${toString dashboardGuestPort}";
                              Restart = "always";
                              RestartSec = 5;
                            };
                          };
                        };
                      }
                    ];
                    specialArgs = {
                      inherit self;
                      inherit (self) inputs;
                      flake-self = self;
                    };
                    inbound = lib.optional settings.dashboard.enable dashboardGuestPort;
                    outbound = [
                      "internet"
                      # the host's own https: local search and llama-cpp
                      "host:443"
                    ]
                    ++ lib.optional settings.homeAssistant.enable "${settings.homeAssistant.address}:${toString settings.homeAssistant.port}";
                    mcp = {
                      enable = mcp;
                      inherit (settings.mcp) allow;
                    };
                    credentials = map credentialName keyProviders;
                    secrets = {
                      "${instanceName}.env" = generators.${generator}.files.".env".path;
                    }
                    // lib.optionalAttrs settings.dashboard.enable {
                      "${instanceName}-dashboard-token" = generators."${instanceName}-dashboard".files.token.path;
                    };
                  };

                  # the proxy sets the real header for the provider's domain;
                  # guestEnv hands the vm a placeholder so hermes accepts the
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
                    dashboard.enable = settings.dashboard.enable;
                    module = {
                      imports = [
                        self.modules.nixos.hermesAgent

                        (
                          { config, flake-self, ... }:
                          {
                            services.hermes-agent = {
                              localProvider.enable = localProvider;
                              dashboard.enable = settings.dashboard.enable;

                              skillDirs =
                                map (
                                  dir: "${config.services.hermes-agent.package}/share/hermes-agent/${dir}"
                                ) settings.packageSkills
                                ++ map (name: "${flake-self.llm.skills.${name}}") settings.skills;

                              overrides = settings.agentSettings;

                              soul = if settings.soul == null then null else flake-self.llm.souls.${settings.soul};
                            };
                          }
                        )
                      ]
                      ++ lib.optional settings.computerUse.enable self.modules.nixos.hermesComputerUse
                      ++ lib.concatMap (channel: channel.modules) active;
                    };
                  };

                  clan.core.vars.generators."${instanceName}-dashboard" = lib.mkIf settings.dashboard.enable {
                    files.token = {
                      owner = "root";
                      group = sshUser;
                      mode = "0440";
                    };
                    runtimeInputs = [ pkgs.openssl ];
                    script = ''
                      openssl rand -hex 32 > "$out/token"
                    '';
                  };

                  users.groups.${sshUser} = lib.mkIf settings.dashboard.enable { };
                  users.users.${sshUser} = lib.mkIf settings.dashboard.enable {
                    isSystemUser = true;
                    group = sshUser;
                    home = "/var/empty";
                    shell = pkgs.bashInteractive;
                    openssh.authorizedKeys.keys =
                      lib.optional (remotePublicKey != "")
                        ''restrict,port-forwarding,permitopen="${dashboardAddress}",command="${tokenCommand}" ${remotePublicKey}'';
                  };

                  clan.core.vars.generators.${generator} = {
                    files = {
                      ".env".secret = true;
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
                        {
                          ${lib.concatStringsSep "\n  " lines}
                        } > "$out/.env"
                        ${lib.concatStringsSep "\n" authorizations}
                      '';
                  };
                };
              };
          };
      };

      roles.client = {
        description = "Connect Hermes Desktop to the server over SSH";
        perInstance =
          {
            instanceName,
            exports,
            roles,
            ...
          }:
          {
            nixosModule =
              {
                config,
                lib,
                pkgs,
                ...
              }:
              let
                serverNames = lib.naturalSort (lib.attrNames (roles.server.machines or { }));
                server = if lib.length serverNames == 1 then lib.head serverNames else null;
                dashboard = server != null && roles.server.machines.${server}.settings.dashboard.enable;
                # every network service exports peer.hosts per machine and
                # networking.priority per instance; walking them here replicates
                # `clan ssh`'s fallback order declaratively. var-typed hosts
                # (tor onions) are machine-local secrets and are skipped.
                peerExports = lib.mapAttrsToList (key: value: {
                  scope = clanLib.parseScope key;
                  inherit value;
                }) (clanLib.selectExports (scope: scope.machineName == server) exports);
                priorityOf =
                  scope:
                  ((exports.${clanLib.buildScopeKey { inherit (scope) serviceName instanceName; }} or { }).networking
                    or { }
                  ).priority or 1000;
                tunnelHosts = lib.pipe peerExports [
                  (lib.filter (entry: (entry.value.peer.hosts or [ ]) != [ ]))
                  (lib.sort (a: b: priorityOf a.scope > priorityOf b.scope))
                  (lib.concatMap (entry: lib.filter (host: host ? plain) entry.value.peer.hosts))
                  (map (host: host.plain))
                  lib.unique
                ];
                normalUsers = lib.attrNames (lib.filterAttrs (_: user: user.isNormalUser) config.users.users);
                clientUser = if lib.length normalUsers == 1 then lib.head normalUsers else null;
                clientGroup = if clientUser == null then null else config.users.users.${clientUser}.group;
                hostKey =
                  if server == null then
                    ""
                  else
                    lib.trim (
                      clanLib.getPublicValue {
                        flake = config.clan.core.settings.directory;
                        machine = server;
                        generator = "openssh";
                        file = "ssh.id_ed25519.pub";
                        default = "";
                      }
                    );
              in
              {
                imports = [ self.modules.nixos.hermesRemote ];

                services.hermes-remote = lib.mkIf (server != null && clientUser != null) {
                  enable = true;
                  user = remoteUser instanceName;
                  hosts = tunnelHosts;
                  # the server resolves <instance>.fencr to the vm
                  remoteAddress = "${instanceName}.fencr:${toString dashboardGuestPort}";
                  identityFile =
                    config.clan.core.vars.generators.${remoteKeyGenerator instanceName}.files."id_ed25519".path;
                  inherit hostKey;
                };

                clan.core.vars.generators.${remoteKeyGenerator instanceName} = lib.mkIf (clientUser != null) {
                  share = true;
                  files = {
                    "id_ed25519" = {
                      owner = clientUser;
                      group = clientGroup;
                      mode = "0400";
                    };
                    "id_ed25519.pub".secret = false;
                  };
                  runtimeInputs = [ pkgs.openssh ];
                  script = ''
                    ssh-keygen -t ed25519 -N "" -C "hermes-remote-${instanceName}" -f "$out/id_ed25519"
                  '';
                };

                assertions = [
                  {
                    assertion = lib.length serverNames == 1;
                    message = "clan hermes client requires exactly one machine with the server role";
                  }
                  {
                    assertion = server == null || tunnelHosts != [ ];
                    message = "clan hermes client found no networking exports with a plain host for ${toString server}";
                  }
                  {
                    assertion = dashboard;
                    message = "clan hermes client: instance ${instanceName} has dashboard.enable = false on ${toString server}";
                  }
                  {
                    assertion = lib.length normalUsers == 1;
                    message = "clan hermes client requires exactly one normal user, found ${toString (lib.length normalUsers)}";
                  }
                  {
                    assertion = server == null || hostKey != "";
                    message = "clan hermes client found no pinned SSH host key for ${toString server}";
                  }
                ];
              };
          };
      };
    };
}
