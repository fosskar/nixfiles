{ self, ... }:
{
  flake.modules."clan.service".hermes =
    { clanLib, ... }:
    let
      basePort = 22100;
    in
    {

      manifest.name = "hermes";
      manifest.description = "Hermes agent server and remote desktop clients";
      manifest.readme = builtins.readFile ./README.md;
      manifest.categories = [ "AI" ];
      manifest.exports.out = [ "dashboard" ];
      manifest.exports.inputs = [
        "peer"
        "networking"
      ];

      roles.server = {
        description = "Host the sealed Hermes agent and its loopback dashboard forward";

        interface =
          { lib, ... }:
          {
            options = {
              id = lib.mkOption {
                type = lib.types.ints.between 0 8;
                default = 0;
                description = "agent vm instance index; derives bridge, subnet and mac.";
              };

              backend = lib.mkOption {
                type = lib.types.enum [
                  "microvm"
                  "container"
                ];
                default = "microvm";
                description = "sandbox running the agent: a sealed microvm or a nixos container on the same bridge posture.";
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

              mcp.enable = lib.mkEnableOption "mcp gateway wiring; the server host must import self.modules.nixos.mcp";

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
              };

              homeAssistant = {
                enable = lib.mkEnableOption "the home assistant integration";
                address = lib.mkOption {
                  type = lib.types.str;
                  default = "192.168.10.50";
                  description = "home assistant IPv4 address; the agent's url and the firewall pinhole both derive from it.";
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
            mkExports,
            ...
          }:
          {
            # the client role reads this instead of deriving the port from the
            # server's settings a second time
            exports = mkExports { dashboard.port = basePort + settings.id; };

            nixosModule =
              {
                config,
                lib,
                pkgs,
                ...
              }:
              let
                generator = "${instanceName}-agent";
                envFile = "${instanceName}.env";
                localProvider = settings.providers.local.enable or false;
                keyProviders = lib.attrNames (
                  lib.filterAttrs (name: provider: provider.enable && name != "local") settings.providers
                );
                isVm = settings.backend == "microvm";
                sandbox = if isVm then "agentVms" else "agentContainers";
                sandboxCfg = config.nixfiles.${sandbox}.${instanceName};
                forwardPort = basePort + settings.id;

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
                          inherit (settings.buzz) channels allowedUsers;
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
                    tcpDestinations = [ { inherit (settings.homeAssistant) address port; } ];
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
                imports = [
                  (if isVm then self.modules.nixos.agentVm else self.modules.nixos.agentContainer)
                ];

                nixfiles.${sandbox}.${instanceName} = {
                  inherit (settings) id;

                  # the sandbox owns the transport: vsock for microvms, tcp over the
                  # bridge for containers
                  forwards = [
                    {
                      listenPort = forwardPort;
                      guestPort = 9119;
                    }
                  ];

                  allowedTCPDestinations = lib.concatMap (channel: channel.tcpDestinations or [ ]) active;

                  services = [
                    self.modules.nixos.hermesAgent

                    (
                      { config, flake-self, ... }:
                      {
                        services.hermes-agent = {
                          localProvider.enable = localProvider;

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

                    # the virtiofs mount does not exist yet when hermes' module merges
                    # environmentFiles into .env at activation, so hand the file to systemd
                    # at start-up instead. hermesAgent itself knows nothing about the vm
                    {
                      systemd.services = {
                        hermes-agent = {
                          serviceConfig.EnvironmentFile = "/run/agent-secrets/${envFile}";
                          unitConfig.RequiresMountsFor = [ "/run/agent-secrets" ];
                        };
                        hermes-dashboard = {
                          serviceConfig.EnvironmentFile = "/run/agent-secrets/${envFile}";
                          unitConfig.RequiresMountsFor = [ "/run/agent-secrets" ];
                        };
                      };
                    }
                  ]
                  ++ lib.concatMap (channel: channel.modules) active
                  ++ lib.optionals settings.mcp.enable [
                    (
                      { lib, ... }:
                      {
                        services.hermes-agent.settings.mcp_servers.nixfiles = {
                          url = "http://${sandboxCfg.hostIp}:${toString config.services.mcpGateway.port}/mcp/";
                          headers.Authorization = "Bearer \${MCP_GATEWAY_TOKEN}";
                          elicitation = {
                            enabled = true;
                            timeout = 300;
                          };
                        };

                        systemd.services.hermes-agent.serviceConfig.EnvironmentFile = lib.mkAfter [
                          "/run/agent-secrets/mcp-gateway.env"
                        ];
                        systemd.services.hermes-dashboard.serviceConfig.EnvironmentFile = lib.mkAfter [
                          "/run/agent-secrets/mcp-gateway.env"
                        ];
                      }
                    )
                  ];

                  secrets = {
                    ${envFile} = config.clan.core.vars.generators.${generator}.files.".env".path;
                    "hermes-dashboard-token" =
                      config.clan.core.vars.generators."${instanceName}-dashboard".files.token.path;
                  }
                  // lib.optionalAttrs settings.mcp.enable {
                    "mcp-gateway.env" = config.clan.core.vars.generators.mcp-gateway.files."token.env".path;
                  };
                };

                systemd.services.mcp-gateway.serviceConfig.IPAddressAllow = lib.mkIf settings.mcp.enable [
                  "${sandboxCfg.ip}/32"
                ];

                networking.firewall.interfaces = lib.mkIf settings.mcp.enable {
                  ${sandboxCfg.bridge}.allowedTCPPorts = [ config.services.mcpGateway.port ];
                };

                clan.core.vars.generators."${instanceName}-dashboard" = {
                  files.token = {
                    owner = "root";
                    group = "root";
                  };
                  runtimeInputs = [ pkgs.openssl ];
                  script = ''
                    openssl rand -hex 32 > "$out/token"
                  '';
                };

                # ssh host alias and root identity come from the sandbox module
                environment.shellAliases.${instanceName} = "ssh -t ${instanceName} -- sudo -iu hermes hermes";

                clan.core.vars.generators.${generator} = {
                  files.".env".secret = true;

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
                      lines =
                        lib.mapAttrsToList (variable: prompt: ''echo "${variable}=$(cat "$prompts/${prompt}")"'') (
                          mergeAttrsOf "env"
                        )
                        ++ map (
                          provider: ''echo "${lib.toUpper provider}_API_KEY=$(cat "$prompts/${provider}-api-key")"''
                        ) keyProviders;
                    in
                    ''
                      {
                        ${lib.concatStringsSep "\n  " lines}
                      } > "$out/.env"
                    '';
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
              { lib, ... }:
              let
                serverNames = lib.naturalSort (lib.attrNames (roles.server.machines or { }));
                server = if lib.length serverNames == 1 then lib.head serverNames else null;
                # the server role publishes its dashboard port for this instance.
                # no fallback: a missing export is an assertion, not a silent 22100
                dashboardExport =
                  if server == null then
                    null
                  else
                    (exports.${
                      clanLib.buildScopeKey {
                        serviceName = "hermes";
                        roleName = "server";
                        machineName = server;
                        inherit instanceName;
                      }
                    } or { }
                    ).dashboard or null;
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
              in
              {
                imports = [ self.modules.nixos.hermesRemote ];

                services.hermes-remote = lib.mkIf (server != null) {
                  enable = true;
                  hosts = tunnelHosts;
                  remotePort = dashboardExport.port;
                  tokenPath = "/run/secrets/vars/per-machine/${server}/${instanceName}-dashboard/token";
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
                    assertion = server == null || dashboardExport != null;
                    message = "clan hermes client found no dashboard export for instance ${instanceName}";
                  }
                ];
              };
          };
      };
    };
}
