{ inputs, ... }:
{
  # sealed nspawn containers to run agents in — the container sibling of
  # agent-vm.nix. containers live on 10.31.x, the vms on 10.30.x. the
  # nftables sealing duplicates the agent-vm rules on purpose: two readable
  # copies beat a shared abstraction for posture-critical rules. `forwards`
  # is the same contract as the vm's, carried over plain tcp on the bridge
  # instead of vsock.
  flake.modules.nixos.agentContainer =
    {
      config,
      flake-self,
      lib,
      pkgs,
      self,
      ...
    }:
    let
      hostConfig = config;
      instances = config.nixfiles.agentContainers;
      hostKey = config.clan.core.vars.generators.openssh.files."ssh.id_ed25519";
      adminKey = lib.trim (
        inputs.clan-core.clanLib.getPublicValue {
          flake = config.clan.core.settings.directory;
          machine = config.clan.core.settings.machine.name;
          generator = "openssh";
          file = "ssh.id_ed25519.pub";
        }
      );
      bridgeOf = name: "brc-${name}";
      forwardLib = import ./_forwards.nix { inherit lib; };
      forwardUnit = name: forward: "${name}-forward-${toString forward.listenPort}";
      # the relay only reaches the container's own address; the bridge is the
      # only network it can see
      forwardHardening = ip: {
        StandardInput = "socket";
        StandardError = "journal";
        DynamicUser = true;
        RestrictAddressFamilies = [ "AF_INET" ];
        IPAddressAllow = [ "${ip}/32" ];
        IPAddressDeny = "any";
        CapabilityBoundingSet = "";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        UMask = "0077";
      };
      forEachInstance = f: lib.mkMerge (lib.mapAttrsToList f instances);
    in
    {
      imports = [ self.modules.nixos.agentForwards ];

      options.nixfiles.agentContainers = lib.mkOption {
        default = { };
        description = "sealed agent containers, keyed by container name.";
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, config, ... }:
            {
              options = {
                id = lib.mkOption {
                  type = lib.types.ints.between 0 8;
                  description = "unique instance index; derives bridge and subnet.";
                };

                services = lib.mkOption {
                  type = lib.types.listOf lib.types.raw;
                  default = [ ];
                  example = lib.literalExpression "[ self.modules.nixos.hermesAgent ]";
                  description = "nixos modules to run inside the container.";
                };

                memoryMax = lib.mkOption {
                  type = lib.types.str;
                  default = "4096M";
                  description = "hard cap on the container unit, enforced by the host.";
                };
                cpuQuota = lib.mkOption {
                  type = lib.types.str;
                  default = "400%";
                };

                secrets = lib.mkOption {
                  type = lib.types.attrsOf lib.types.path;
                  default = { };
                  example = lib.literalExpression ''
                    { "hermes.env" = config.clan.core.vars.generators.hermes-agent.files.".env".path; }
                  '';
                  description = ''
                    host files to stage and bind read-only into the container, keyed
                    by the name they get under /run/agent-secrets. clan renders
                    secrets into a tree the container must never see wholesale,
                    hence copying rather than binding that tree.
                  '';
                };

                allowedTCPDestinations = lib.mkOption {
                  type = lib.types.listOf (
                    lib.types.submodule {
                      options = {
                        address = lib.mkOption {
                          type = lib.types.str;
                        };
                        port = lib.mkOption {
                          type = lib.types.port;
                        };
                      };
                    }
                  );
                  default = [ ];
                  description = "private IPv4 TCP destinations reachable from the container.";
                };

                forwards = lib.mkOption {
                  inherit (forwardLib) type;
                  default = [ ];
                  description = "host endpoints forwarded to guest ports over the bridge.";
                };

                bridge = lib.mkOption {
                  type = lib.types.str;
                  default = bridgeOf name;
                };
                hostIp = lib.mkOption {
                  type = lib.types.str;
                  default = "10.31.${toString (config.id + 1)}.1";
                  description = "the host's address on the bridge, and the container's gateway.";
                };
                ip = lib.mkOption {
                  type = lib.types.str;
                  default = "10.31.${toString (config.id + 1)}.2";
                };
                prefixLength = lib.mkOption {
                  type = lib.types.int;
                  default = 24;
                };
                dns = lib.mkOption {
                  type = lib.types.str;
                  default = builtins.head hostConfig.networking.nameservers;
                  defaultText = "the host's first resolver";
                };
              };
            }
          )
        );
      };

      config = {
        assertions = [
          {
            assertion = lib.allUnique (lib.mapAttrsToList (_: cfg: cfg.id) instances);
            message = "nixfiles.agentContainers: instance ids must be unique.";
          }
          {
            # nspawn caps container names at 11 chars so the veth fits
            # IFNAMSIZ; the bridge prefix lands on the same limit
            assertion = lib.all (name: lib.stringLength name <= 11) (lib.attrNames instances);
            message = "nixfiles.agentContainers: container names must be at most 11 chars.";
          }
        ];

        nixfiles.agentForwardEndpoints = forwardLib.endpointsOf instances;

        # root on the host is the only thing that can reach the bridges, so
        # `ssh <container-name>` from the host logs in as root
        programs.ssh.extraConfig = lib.concatStrings (
          lib.mapAttrsToList (name: cfg: ''
            Host ${name} ${cfg.ip}
              HostName ${cfg.ip}
              User root
              IdentityFile ${hostKey.path}
              IdentitiesOnly yes
              StrictHostKeyChecking accept-new
          '') instances
        );

        systemd.tmpfiles.rules = lib.mapAttrsToList (
          name: _: "d /var/lib/agent-containers/${name} 0755 root root - -"
        ) instances;

        # the sandbox dir is the guests' /var/lib. a stopped guest is
        # consistent whatever it stores, so quiesce rather than teach this
        # module about any particular payload. only guests that were running
        # get restarted, so a deliberately stopped one stays stopped; the trap
        # makes sure a failed copy still brings them back.
        clan.core.state.agent-containers = lib.mkIf (instances != { }) {
          folders = [ "/var/backup/agent-containers" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.rsync
                pkgs.coreutils
                pkgs.systemd
              ]
            }
            active=""
            for unit in ${
              lib.concatMapStringsSep " " (name: "container@${name}.service") (lib.attrNames instances)
            }; do
              if systemctl is-active --quiet "$unit"; then
                active="$active $unit"
              fi
            done
            # --no-block: the staging copy is already frozen, so the job must
            # not wait on the guest's readiness notification
            restart() {
              if [ -n "$active" ]; then
                systemctl start --no-block $active
              fi
            }
            trap restart EXIT
            if [ -n "$active" ]; then
              systemctl stop $active
            fi
            mkdir -p /var/backup/agent-containers
            rsync -a --delete /var/lib/agent-containers/ /var/backup/agent-containers/
          '';
        };

        systemd.services = forEachInstance (
          name: cfg:
          {
            "${name}-container-secrets" = lib.mkIf (cfg.secrets != { }) {
              description = "stage secrets for the ${name} container";
              wantedBy = [ "container@${name}.service" ];
              before = [ "container@${name}.service" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = false;
              };
              script = ''
                install -d -m 0700 /var/lib/agent-container/${name}
                install -d -m 0755 /var/lib/agent-container/${name}/secrets
                ${lib.concatStringsSep "\n" (
                  lib.mapAttrsToList (
                    secretName: src: "install -m 0400 ${src} /var/lib/agent-container/${name}/secrets/${secretName}"
                  ) cfg.secrets
                )}
              '';
            };

            # the container cannot outgrow this even if an agent misbehaves
            "container@${name}".serviceConfig = {
              MemoryMax = cfg.memoryMax;
              CPUQuota = cfg.cpuQuota;
              CPUWeight = 20;
            };
          }
          // lib.listToAttrs (
            map (forward: {
              name = "${forwardUnit name forward}@";
              value = {
                description = "forward to ${name} guest port ${toString forward.guestPort}";
                after = [ "container@${name}.service" ];
                requires = [ "container@${name}.service" ];
                serviceConfig = forwardHardening cfg.ip // {
                  ExecStart = "${pkgs.socat}/bin/socat STDIO TCP:${cfg.ip}:${toString forward.guestPort}";
                };
              };
            }) cfg.forwards
          )
        );

        systemd.sockets = forEachInstance (
          name: cfg:
          lib.listToAttrs (
            map (forward: {
              name = forwardUnit name forward;
              value = {
                description = "forward to ${name} guest port ${toString forward.guestPort}";
                wantedBy = [ "sockets.target" ];
                listenStreams = [ "${forward.listenAddress}:${toString forward.listenPort}" ];
                socketConfig = {
                  Accept = true;
                  MaxConnections = 64;
                };
              };
            }) cfg.forwards
          )
        );

        containers = lib.mapAttrs (name: cfg: {
          autoStart = true;
          privateNetwork = true;
          hostBridge = cfg.bridge;
          localAddress = "${cfg.ip}/${toString cfg.prefixLength}";
          specialArgs = {
            inherit flake-self inputs self;
            agentSandbox = cfg // {
              inherit adminKey name;
              kind = "container";
              # the host relay crosses the bridge, so a forwarded service must
              # listen on more than loopback
              bindAddress = "0.0.0.0";
            };
          };
          bindMounts = {
            "/var/lib" = {
              hostPath = "/var/lib/agent-containers/${name}";
              isReadOnly = false;
            };
          }
          // lib.optionalAttrs (cfg.secrets != { }) {
            "/run/agent-secrets" = {
              hostPath = "/var/lib/agent-container/${name}/secrets";
              isReadOnly = true;
            };
          };
          config =
            { ... }:
            {
              imports = [ self.modules.nixos.agentContainerBase ] ++ cfg.services;
              # reuse host pkgs so the containers see the repo overlays
              # (pkgs.local) and share evaluations, like the microvms do
              nixpkgs.pkgs = pkgs;
            };
        }) instances;

        # masquerade by the container's source address instead of
        # networking.nat, so the module needs no knowledge of the host's
        # uplink interface
        boot.kernel.sysctl."net.ipv4.conf.all.forwarding" = lib.mkDefault true;

        networking.nftables.tables.agent-container-nat = lib.mkIf (instances != { }) {
          family = "ip";
          content = ''
            chain postrouting {
              type nat hook postrouting priority srcnat; policy accept;
              ${lib.concatStrings (
                lib.mapAttrsToList (_: cfg: ''
                  ip saddr ${cfg.ip} oifname != "${cfg.bridge}" masquerade
                '') instances
              )}
            }
          '';
        };

        # nspawn enslaves the container's vb- veth to the bridge itself, so
        # only the bridge needs declaring
        systemd.network = forEachInstance (
          _: cfg: {
            netdevs."10-${cfg.bridge}".netdevConfig = {
              Name = cfg.bridge;
              Kind = "bridge";
            };
            networks."10-${cfg.bridge}" = {
              matchConfig.Name = cfg.bridge;
              networkConfig = {
                Address = "${cfg.hostIp}/${toString cfg.prefixLength}";
                ConfigureWithoutCarrier = true;
              };
            };
          }
        );

        networking.firewall = {
          # caddy fronts everything a local agent consumes and runs on this
          # host, so the one reachable service points at ourselves rather
          # than across the lan
          interfaces = forEachInstance (
            _: cfg: {
              ${cfg.bridge}.allowedTCPPorts = [
                80
                443
              ];
            }
          );

          filterForward = true;
          # internet stays open; every private range is dropped, so a
          # compromised agent cannot walk the lan, the netbird mesh, or a
          # sibling agent's subnet
          extraForwardRules = lib.concatStrings (
            lib.mapAttrsToList (_: cfg: ''
              iifname "${cfg.bridge}" meta nfproto ipv6 drop
              iifname "${cfg.bridge}" ip daddr ${cfg.dns} udp dport 53 accept
              iifname "${cfg.bridge}" ip daddr ${cfg.dns} tcp dport 53 accept
              ${lib.concatMapStringsSep "\n" (
                destination:
                ''iifname "${cfg.bridge}" ip daddr ${destination.address} tcp dport ${toString destination.port} accept''
              ) cfg.allowedTCPDestinations}
              iifname "${cfg.bridge}" ip daddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 100.64.0.0/10, 169.254.0.0/16 } drop
              iifname "${cfg.bridge}" accept
              oifname "${cfg.bridge}" ct state established,related accept
            '') instances
          );
        };

        # the main firewall's interface rules only add ports, so globally
        # open ones (sshd at least) stay reachable from the bridges. this
        # chain runs before the main firewall and seals the containers' host
        # access to each bridge's declared allowedTCPPorts
        networking.nftables.tables.agent-container-seal = lib.mkIf (instances != { }) (
          let
            bridgeSet = "{ ${
              lib.concatMapStringsSep ", " (bridge: "\"${bridge}\"") (
                lib.mapAttrsToList (_: cfg: cfg.bridge) instances
              )
            } }";
            portsOf = cfg: lib.unique config.networking.firewall.interfaces.${cfg.bridge}.allowedTCPPorts;
          in
          {
            family = "inet";
            content = ''
              chain input {
                type filter hook input priority filter - 1; policy accept;
                iifname ${bridgeSet} ct state established,related accept
                ${lib.concatStrings (
                  lib.mapAttrsToList (_: cfg: ''
                    iifname "${cfg.bridge}" tcp dport { ${lib.concatMapStringsSep ", " toString (portsOf cfg)} } accept
                  '') instances
                )}
                iifname ${bridgeSet} counter drop
              }
            '';
          }
        );
      };
    };

  # the environment itself: network posture and ssh access. state lives on
  # the host in /var/lib/agent-containers/<name>, bind-mounted at /var/lib.
  flake.modules.nixos.agentContainerBase =
    {
      agentSandbox,
      lib,
      pkgs,
      ...
    }:
    {
      # the container init assigns localAddress to eth0; gateway and dns are
      # ours to set. v4 only, matching the host's v4-only forward rules
      networking = {
        useDHCP = false;
        useHostResolvConf = false;
        defaultGateway = agentSandbox.hostIp;
        nameservers = [ agentSandbox.dns ];
        firewall.enable = true;
        # the host relay crosses the bridge, so every forwarded port has to be
        # reachable on the container's address
        firewall.allowedTCPPorts = map (forward: forward.guestPort) agentSandbox.forwards;
      };

      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
      };

      users.users.root.openssh.authorizedKeys.keys = [ agentSandbox.adminKey ];

      # fetch tools for whatever runs inside; language runtimes ship with
      # the agent that needs them
      environment.systemPackages = [
        pkgs.curl
        pkgs.git
      ];

      system.stateVersion = lib.versions.majorMinor lib.version;
    };
}
