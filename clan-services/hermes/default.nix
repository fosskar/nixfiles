{ self }:
{ clanLib, ... }:
let
  basePort = 22100;
in
{
  _class = "clan.service";

  manifest.name = "hermes";
  manifest.description = "Hermes agent server and remote desktop clients";
  manifest.readme = builtins.readFile ./README.md;
  manifest.categories = [ "AI" ];
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
          };

          signal.enable = lib.mkEnableOption "the signal channel";

          homeAssistant = {
            enable = lib.mkEnableOption "the home assistant integration";
            url = lib.mkOption {
              type = lib.types.str;
              default = "http://homeassistant.lan:8123";
            };
            address = lib.mkOption {
              type = lib.types.str;
              default = "192.168.10.50";
              description = "home assistant IPv4 address, opened as a firewall pinhole from the vm.";
            };
            port = lib.mkOption {
              type = lib.types.port;
              default = 8123;
            };
          };
        };
      };

    perInstance =
      { instanceName, settings, ... }:
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
            envFile = "${instanceName}.env";
            localProvider = settings.providers.local.enable or false;
            keyProviders = lib.attrNames (
              lib.filterAttrs (name: provider: provider.enable && name != "local") settings.providers
            );
            isVm = settings.backend == "microvm";
            sandbox = if isVm then "agentVms" else "agentContainers";
            sandboxCfg = config.nixfiles.${sandbox}.${instanceName};
            sandboxUnit =
              if isVm then "microvm@${instanceName}.service" else "container@${instanceName}.service";
            forwardPort = basePort + settings.id;
            hybridVsockConnect = pkgs.writers.writeRustBin "hermes-hybrid-vsock-connect" {
              rustcArgs = [
                "-O"
                "--edition"
                "2021"
              ];
            } ./hybrid-vsock-connect.rs;
          in
          {
            imports = [
              (if isVm then self.modules.nixos.agentVm else self.modules.nixos.agentContainer)
            ];

            nixfiles.${sandbox}.${instanceName} = {
              inherit (settings) id;

              allowedTCPDestinations = lib.optional settings.homeAssistant.enable {
                inherit (settings.homeAssistant) address port;
              };

              services = [
                self.modules.nixos.hermesAgent

                (
                  {
                    config,
                    flake-self,
                    lib,
                    pkgs,
                    ...
                  }:
                  let
                    externalDirs =
                      map (
                        dir: "${config.services.hermes-agent.package}/share/hermes-agent/${dir}"
                      ) settings.packageSkills
                      ++ map (name: "${flake-self.llm.skills.${name}}") settings.skills;

                    defaults = {
                      timezone = "Europe/Berlin";
                      display.personality = "none";
                      terminal.backend = "local";
                      tts.provider = "piper";
                      stt = {
                        provider = "local";
                        local.model = "base";
                      };
                      # own searxng instead of the paid search apis hermes defaults to
                      web.search_backend = "searxng";
                      # standalone plugins are opt-in; bundled platform/backend ones
                      # (matrix, searxng) auto-load and are not affected by this list
                      plugins.enabled = [
                        "disk-cleanup"
                        "hermes-achievements"
                      ];
                    }
                    // lib.optionalAttrs localProvider {
                      providers.local = {
                        name = "Local";
                        api = "https://llama-cpp.${flake-self.domains.local}/v1";
                        api_key = "no-key-required";
                        # the only alias llama-cpp preloads; models-max = 1, so naming
                        # any other one costs a model swap on the first request
                        default_model = "qwen3.6-35b-a3b-mtp";
                        context_length = 131072;
                      };
                      # agentSettings.model overrides this
                      model = {
                        default = "qwen3.6-35b-a3b-mtp";
                        provider = "local";
                        context_length = 131072;
                      };
                    };
                  in
                  {
                    services.hermes-agent = {
                      settings = lib.recursiveUpdate (lib.recursiveUpdate defaults settings.agentSettings) (
                        lib.optionalAttrs (externalDirs != [ ]) { skills.external_dirs = externalDirs; }
                      );

                      environment.SEARXNG_URL = "https://search.${flake-self.domains.local}/";
                    };

                    # reinstalled on every activation: the soul is declarative,
                    # agent edits do not survive
                    system.activationScripts.hermes-agent-soul = lib.mkIf (settings.soul != null) (
                      lib.stringAfter [ "hermes-agent-setup" ] ''
                        ${pkgs.coreutils}/bin/install \
                          -o ${config.services.hermes-agent.user} \
                          -g ${config.services.hermes-agent.group} \
                          -m 0444 \
                          ${flake-self.llm.souls.${settings.soul}} \
                          ${config.services.hermes-agent.stateDir}/.hermes/SOUL.md
                      ''
                    );
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
              ++ lib.optionals settings.matrix.enable [
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
                  };
                }
              ]
              ++ lib.optional settings.signal.enable self.modules.nixos.hermesSignal
              ++ lib.optionals settings.homeAssistant.enable [
                self.modules.nixos.hermesHomeAssistant
                { services.hermes-agent.homeAssistant.url = settings.homeAssistant.url; }
              ]
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

            systemd.sockets."${instanceName}-dashboard-forward" = {
              description = "Hermes dashboard forward";
              wantedBy = [ "sockets.target" ];
              listenStreams = [ "127.0.0.1:${toString forwardPort}" ];
              socketConfig = {
                Accept = true;
                MaxConnections = 64;
              };
            };

            systemd.services."${instanceName}-dashboard-forward@" = {
              description = "Hermes dashboard connection forward";
              after = [ sandboxUnit ];
              requires = [ sandboxUnit ];
              serviceConfig = {
                StandardInput = "socket";
                StandardError = "journal";
                CapabilityBoundingSet = "";
                LockPersonality = true;
                MemoryDenyWriteExecute = true;
                NoNewPrivileges = true;
                PrivateDevices = true;
                PrivateTmp = true;
                ProtectHome = true;
                ProtectClock = true;
                ProtectControlGroups = true;
                ProtectSystem = "strict";
                ProtectHostname = true;
                ProtectKernelLogs = true;
                ProtectKernelModules = true;
                ProtectKernelTunables = true;
                RestrictNamespaces = true;
                RestrictRealtime = true;
                RestrictSUIDSGID = true;
                SystemCallArchitectures = "native";
                UMask = "0077";
              }
              // (
                if isVm then
                  {
                    User = "microvm";
                    Group = "kvm";
                    ExecStart = "${hybridVsockConnect}/bin/hermes-hybrid-vsock-connect /var/lib/microvms/${instanceName}/notify.vsock 9119";
                    RestrictAddressFamilies = [ "AF_UNIX" ];
                  }
                else
                  {
                    DynamicUser = true;
                    ExecStart = "${pkgs.socat}/bin/socat STDIO TCP:${sandboxCfg.ip}:9119";
                    RestrictAddressFamilies = [ "AF_INET" ];
                    IPAddressAllow = [ "${sandboxCfg.ip}/32" ];
                    IPAddressDeny = "any";
                  }
              );
            };

            clan.core.vars.generators.${generator} = {
              files.".env".secret = true;

              prompts =
                lib.optionalAttrs settings.matrix.enable {
                  matrix-password = {
                    description = "matrix password for ${settings.matrix.userId}";
                    type = "hidden";
                    persist = true;
                  };
                  matrix-recovery-key = {
                    description = "Matrix recovery key for ${settings.matrix.userId}";
                    type = "hidden";
                    persist = true;
                  };
                }
                // lib.optionalAttrs settings.signal.enable {
                  signal-account-number = {
                    description = "Signal account phone number in E.164 format";
                    type = "hidden";
                    persist = true;
                  };
                }
                // lib.optionalAttrs settings.homeAssistant.enable {
                  home-assistant-token = {
                    description = "Home Assistant long-lived access token for the agent";
                    type = "hidden";
                    persist = true;
                  };
                }
                // lib.listToAttrs (
                  map (provider: {
                    name = "${provider}-api-key";
                    value = {
                      description = "${provider} API key";
                      type = "hidden";
                      persist = true;
                    };
                  }) keyProviders
                );

              script =
                let
                  lines =
                    lib.optionals settings.matrix.enable [
                      ''echo "MATRIX_PASSWORD=$(cat "$prompts/matrix-password")"''
                      ''echo "MATRIX_RECOVERY_KEY=$(cat "$prompts/matrix-recovery-key")"''
                    ]
                    ++ map (
                      provider: ''echo "${lib.toUpper provider}_API_KEY=$(cat "$prompts/${provider}-api-key")"''
                    ) keyProviders
                    ++ lib.optional settings.homeAssistant.enable ''echo "HASS_TOKEN=$(cat "$prompts/home-assistant-token")"''
                    ++ lib.optionals settings.signal.enable [
                      ''echo "SIGNAL_ACCOUNT=$(cat "$prompts/signal-account-number")"''
                      ''echo "SIGNAL_ALLOWED_USERS=$(cat "$prompts/signal-account-number")"''
                    ];
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
            serverSettings = (roles.server.machines.${server} or { }).settings or { };
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
              remotePort = basePort + (serverSettings.id or 0);
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
            ];
          };
      };
  };
}
