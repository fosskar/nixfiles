{ inputs, ... }:
{
  # sealed microvms to run agents in. each instance provides the environment —
  # private bridge, nat to the internet, a firewall that drops every private
  # range, a persistent /var/lib and room to install into — and knows nothing
  # about which agent runs there. a machine says what to put inside:
  #
  #   nixfiles.agentVms.hermes.services = [ self.modules.nixos.hermesAgent ];
  #
  # per-instance networking (bridge, subnet, tap, mac, vsock cid) derives from
  # the instance's id, so instances never collide. reaching a service inside is
  # this module's business too: `forwards` maps a host endpoint to a guest port
  # and the whole path — socket unit, vsock connector, guest-side proxy — lives
  # here, so callers never name a transport.
  flake.modules.nixos.agentVm =
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
      instances = config.nixfiles.agentVms;
      # this host's sshd key, doubling as root's client identity into the vms.
      # the vms have no clan config of their own, so resolve the public half
      # here and hand it over. rotating this host's key locks root out of the
      # vms until the next deploy
      hostKey = config.clan.core.vars.generators.openssh.files."ssh.id_ed25519";
      adminKey = lib.trim (
        inputs.clan-core.clanLib.getPublicValue {
          flake = config.clan.core.settings.directory;
          machine = config.clan.core.settings.machine.name;
          generator = "openssh";
          file = "ssh.id_ed25519.pub";
        }
      );
      tapOf = name: "tap-${name}";
      bridgeOf = name: "br-${name}";
      macOf = cfg: "02:00:00:00:20:0${toString (cfg.id + 1)}";
      forwardLib = import ./_forwards.nix { inherit lib; };
      forwardUnit = name: forward: "${name}-forward-${toString forward.listenPort}";
      hostForwardUnit = name: forward: "${name}-host-forward-${toString forward.vsockPort}";
      vsockForward = pkgs.writers.writeRustBin "agent-vsock-forward" {
        rustcArgs = [
          "-O"
          "--edition"
          "2021"
        ];
      } ./vsock-forward.rs;
      forwardHardening = {
        StandardInput = "socket";
        StandardError = "journal";
        User = "microvm";
        Group = "kvm";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_VSOCK"
        ];
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
      imports = [
        inputs.microvm.nixosModules.host
        self.modules.nixos.agentForwards
      ];

      options.nixfiles.agentVms = lib.mkOption {
        default = { };
        description = "sealed agent microvms, keyed by vm name.";
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, config, ... }:
            {
              options = {
                id = lib.mkOption {
                  type = lib.types.ints.between 0 8;
                  description = "unique instance index; derives bridge, subnet, tap, mac and vsock cid.";
                };

                services = lib.mkOption {
                  type = lib.types.listOf lib.types.raw;
                  default = [ ];
                  example = lib.literalExpression "[ self.modules.nixos.hermesAgent ]";
                  description = "nixos modules to run inside the vm.";
                };

                vcpu = lib.mkOption {
                  type = lib.types.int;
                  default = 4;
                };
                mem = lib.mkOption {
                  type = lib.types.int;
                  default = 4096;
                  description = "guest memory ceiling; free page reporting returns unused memory to the host.";
                };
                memoryMax = lib.mkOption {
                  type = lib.types.str;
                  default = "4608M";
                  description = "hard cap on the whole vm unit, enforced by the host; guest ceiling plus hypervisor overhead.";
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
                    host files to stage and share read-only into the vm, keyed by the
                    name they get under /run/agent-secrets. clan renders secrets into a
                    tree the vm must never see wholesale, hence copying rather than
                    sharing that tree.
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
                  description = "private IPv4 TCP destinations reachable from the vm.";
                };

                forwards = lib.mkOption {
                  inherit (forwardLib) type;
                  default = [ ];
                  description = "host endpoints forwarded to guest ports over vsock.";
                };

                hostForwards = lib.mkOption {
                  type = lib.types.listOf (
                    lib.types.submodule {
                      options = {
                        vsockPort = lib.mkOption { type = lib.types.port; };
                        targetPort = lib.mkOption { type = lib.types.port; };
                      };
                    }
                  );
                  default = [ ];
                  description = "guest loopback ports forwarded to host ports over vsock.";
                };

                bridge = lib.mkOption {
                  type = lib.types.str;
                  default = bridgeOf name;
                };
                hostIp = lib.mkOption {
                  type = lib.types.str;
                  default = "10.30.${toString (config.id + 1)}.1";
                  description = "the host's address on the bridge, and the vm's gateway.";
                };
                ip = lib.mkOption {
                  type = lib.types.str;
                  default = "10.30.${toString (config.id + 1)}.2";
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
        boot.kernelModules = lib.mkIf (instances != { }) [ "vhost_vsock" ];

        assertions = [
          {
            assertion = lib.allUnique (lib.mapAttrsToList (_: cfg: cfg.id) instances);
            message = "nixfiles.agentVms: instance ids must be unique.";
          }
          {
            # IFNAMSIZ caps interface names at 15 chars
            assertion = lib.all (name: lib.stringLength (tapOf name) <= 15) (lib.attrNames instances);
            message = "nixfiles.agentVms: vm names must be at most ${
              toString (15 - lib.stringLength (tapOf ""))
            } chars, so tap and bridge names fit IFNAMSIZ.";
          }
        ];

        nixfiles.agentForwardEndpoints = forwardLib.endpointsOf instances;

        # the sandbox dir is the guests' /var/lib. a stopped guest is
        # consistent whatever it stores, so quiesce rather than teach this
        # module about any particular payload. only guests that were running
        # get restarted, so a deliberately stopped one stays stopped; the trap
        # makes sure a failed copy still brings them back.
        clan.core.state.agent-vms = lib.mkIf (instances != { }) {
          folders = [ "/var/backup/agent-vms" ];
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
              lib.concatMapStringsSep " " (name: "microvm@${name}.service") (lib.attrNames instances)
            }; do
              if systemctl is-active --quiet "$unit"; then
                active="$active $unit"
              fi
            done
            # --no-block: the staging copy is already frozen, so the job must
            # not wait on the guest's readiness notification (microvm@ is
            # Type=notify with a 2m30s timeout and reports ready late)
            restart() {
              if [ -n "$active" ]; then
                systemctl start --no-block $active
              fi
            }
            trap restart EXIT
            if [ -n "$active" ]; then
              systemctl stop $active
            fi
            mkdir -p /var/backup/agent-vms
            rsync -a --delete /var/lib/agent-vms/ /var/backup/agent-vms/
          '';
        };

        # root on the host is the only thing that can reach the bridges, so
        # `ssh <vm-name>` from the host logs in as root
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

        systemd.services = lib.mkMerge (
          [
            # microvm.nix upstream script trips SC2046
            { "microvm-set-booted@".enableStrictShellChecks = false; }
          ]
          ++ lib.mapAttrsToList (name: cfg: {
            "${name}-vm-secrets" = lib.mkIf (cfg.secrets != { }) {
              description = "stage secrets for the ${name} vm";
              wantedBy = [ "microvm@${name}.service" ];
              before = [ "microvm@${name}.service" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = false;
              };
              script = ''
                install -d -m 0700 /var/lib/agent-vm/${name}
                install -d -m 0755 /var/lib/agent-vm/${name}/secrets
                ${lib.concatStringsSep "\n" (
                  lib.mapAttrsToList (
                    secretName: src: "install -m 0400 ${src} /var/lib/agent-vm/${name}/secrets/${secretName}"
                  ) cfg.secrets
                )}
              '';
            };

            # migrates the retired volume image once
            "${name}-vm-state" = {
              description = "state dir for the ${name} vm";
              wantedBy = [ "microvm@${name}.service" ];
              before = [ "microvm@${name}.service" ];
              path = [ pkgs.util-linux ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = false;
              };
              script = ''
                install -d -m 0755 /var/lib/agent-vms/${name}
                img=/var/lib/microvms/${name}/agent-vm-state.img
                if [ -f "$img" ] && [ -z "$(ls -A /var/lib/agent-vms/${name})" ]; then
                  mnt=$(mktemp -d)
                  mount -o loop,ro "$img" "$mnt"
                  cp -a "$mnt"/. /var/lib/agent-vms/${name}/
                  umount "$mnt"
                  rmdir "$mnt"
                  mv "$img" "$img.migrated"
                fi
              '';
            };

            # the vm cannot outgrow this even if an agent misbehaves; the in-vm
            # balloon hands unused memory back below the cap
            "microvm@${name}".serviceConfig = {
              MemoryMax = cfg.memoryMax;
              CPUQuota = cfg.cpuQuota;
              CPUWeight = 20;
            };
          }) instances
          ++ lib.concatLists (
            lib.mapAttrsToList (
              name: cfg:
              map (forward: {
                "${forwardUnit name forward}@" = {
                  description = "forward to ${name} guest port ${toString forward.guestPort}";
                  after = [ "microvm@${name}.service" ];
                  requires = [ "microvm@${name}.service" ];
                  # per-connection instances must not pile up in failed state
                  unitConfig.CollectMode = "inactive-or-failed";
                  serviceConfig = forwardHardening // {
                    ExecStart = "${pkgs.socat}/bin/socat STDIO VSOCK-CONNECT:${toString (3 + cfg.id)}:${toString forward.guestPort}";
                  };
                };
              }) cfg.forwards
            ) instances
          )
          ++ lib.concatLists (
            lib.mapAttrsToList (
              name: cfg:
              map (forward: {
                "${hostForwardUnit name forward}@" = {
                  description = "host forward for ${name} vsock port ${toString forward.vsockPort}";
                  after = [ "microvm@${name}.service" ];
                  requires = [ "microvm@${name}.service" ];
                  unitConfig.CollectMode = "inactive-or-failed";
                  serviceConfig = forwardHardening // {
                    ExecStart = "${vsockForward}/bin/agent-vsock-forward ${toString (3 + cfg.id)} ${toString forward.targetPort}";
                  };
                };
              }) cfg.hostForwards
            ) instances
          )
        );

        systemd.sockets =
          forEachInstance (
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
          )
          // forEachInstance (
            name: cfg:
            lib.listToAttrs (
              map (forward: {
                name = hostForwardUnit name forward;
                value = {
                  description = "host forward for ${name} vsock port ${toString forward.vsockPort}";
                  wantedBy = [ "sockets.target" ];
                  listenStreams = [ "vsock::${toString forward.vsockPort}" ];
                  socketConfig = {
                    Accept = true;
                    MaxConnections = 64;
                  };
                };
              }) cfg.hostForwards
            )
          );

        microvm.vms = lib.mapAttrs (name: cfg: {
          autostart = true;
          specialArgs = {
            inherit flake-self inputs self;
            agentSandbox = cfg // {
              inherit adminKey name;
              kind = "microvm";
              # the guest-side proxy relays vsock to loopback, so a forwarded
              # service only ever needs to listen on loopback
              bindAddress = "127.0.0.1";
              hasSecrets = cfg.secrets != { };
              tap = tapOf name;
              mac = macOf cfg;
              vsockCid = 3 + cfg.id;
            };
          };
          config =
            { ... }:
            {
              imports = [ self.modules.nixos.agentVmBase ] ++ cfg.services;
            };
        }) instances;

        # masquerade by the vm's source address instead of networking.nat, so
        # the module needs no knowledge of the host's uplink interface
        boot.kernel.sysctl."net.ipv4.conf.all.forwarding" = lib.mkDefault true;

        networking.nftables.tables.agent-vm-nat = lib.mkIf (instances != { }) {
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

        systemd.network = forEachInstance (
          name: cfg: {
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
            networks."11-${tapOf name}" = {
              matchConfig.Name = tapOf name;
              networkConfig.Bridge = cfg.bridge;
            };
          }
        );

        networking.firewall = {
          # caddy fronts everything a local agent consumes and runs on this
          # host, so the one reachable service points at ourselves rather than
          # across the lan
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
          # sibling agent vm's subnet
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
        # chain runs before the main firewall and seals the vms' host access
        # to each bridge's declared allowedTCPPorts
        networking.nftables.tables.agent-vm-seal = lib.mkIf (instances != { }) (
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

  # the environment itself: hardware shape, network posture, and a /var/lib
  # that survives reboots so whatever is installed inside keeps its state.
  flake.modules.nixos.agentVmBase =
    {
      agentSandbox,
      lib,
      pkgs,
      ...
    }:
    {
      microvm = {
        hypervisor = "qemu";
        inherit (agentSandbox) vcpu mem;
        balloon = true;
        deflateOnOOM = true;
        vsock.cid = agentSandbox.vsockCid;

        interfaces = [
          {
            type = "tap";
            id = agentSandbox.tap;
            inherit (agentSandbox) mac;
          }
        ];

        shares = [
          {
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
            tag = "ro-store";
            proto = "virtiofs";
          }
        ]
        ++ lib.optional agentSandbox.hasSecrets {
          source = "/var/lib/agent-vm/${agentSandbox.name}/secrets";
          mountPoint = "/run/agent-secrets";
          tag = "secrets";
          proto = "virtiofs";
        }
        ++ [
          {
            # every agent keeps its state under /var/lib, so share the whole
            # tree rather than making each one declare a directory
            source = "/var/lib/agent-vms/${agentSandbox.name}";
            mountPoint = "/var/lib";
            tag = "state";
            proto = "virtiofs";
          }
        ];
      };

      # the host connects over vsock, so every forwarded port needs a listener
      # on the guest side of it. the relayed service itself only binds loopback
      systemd.services = lib.listToAttrs (
        map (forward: {
          name = "agent-vsock-proxy-${toString forward.guestPort}";
          value = {
            description = "vsock proxy for port ${toString forward.guestPort}";
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              ExecStart = "${pkgs.socat}/bin/socat VSOCK-LISTEN:${toString forward.guestPort},fork TCP:127.0.0.1:${toString forward.guestPort}";
              Restart = "always";
              RestartSec = 5;
              DynamicUser = true;
              CapabilityBoundingSet = "";
              IPAddressAllow = "localhost";
              IPAddressDeny = "any";
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
              RestrictAddressFamilies = [
                "AF_INET"
                "AF_VSOCK"
              ];
              RestrictNamespaces = true;
              RestrictRealtime = true;
              RestrictSUIDSGID = true;
              SystemCallArchitectures = "native";
              UMask = "0077";
            };
          };
        }) agentSandbox.forwards
        ++ map (forward: {
          name = "agent-vsock-host-proxy-${toString forward.targetPort}";
          value = {
            description = "host vsock proxy for port ${toString forward.targetPort}";
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              ExecStart = "${pkgs.socat}/bin/socat TCP4-LISTEN:${toString forward.targetPort},bind=127.0.0.1,fork VSOCK-CONNECT:2:${toString forward.vsockPort}";
              Restart = "always";
              RestartSec = 5;
              DynamicUser = true;
              CapabilityBoundingSet = "";
              IPAddressAllow = "localhost";
              IPAddressDeny = "any";
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
              RestrictAddressFamilies = [
                "AF_INET"
                "AF_VSOCK"
              ];
              RestrictNamespaces = true;
              RestrictRealtime = true;
              RestrictSUIDSGID = true;
              SystemCallArchitectures = "native";
              UMask = "0077";
            };
          };
        }) agentSandbox.hostForwards
      );

      networking = {
        useDHCP = false;
        useNetworkd = true;
        firewall.enable = true;
      };

      # virtio gives unpredictable enp0sN names, so match the mac we assigned.
      # v4 only: no RA-assigned v6 for the host's v4 forward rules to miss
      systemd.network.networks."10-lan" = {
        matchConfig.MACAddress = agentSandbox.mac;
        networkConfig = {
          Address = "${agentSandbox.ip}/${toString agentSandbox.prefixLength}";
          Gateway = agentSandbox.hostIp;
          DNS = agentSandbox.dns;
          IPv6AcceptRA = false;
          LinkLocalAddressing = "ipv4";
        };
      };

      # /etc is rebuilt on every boot, so keep the host key on the state
      # volume; otherwise the host's known_hosts breaks each time
      systemd.tmpfiles.rules = [ "d /var/lib/ssh 0700 root root - -" ];

      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
        hostKeys = [
          {
            path = "/var/lib/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
        ];
      };

      users.users.root.openssh.authorizedKeys.keys = [ agentSandbox.adminKey ];

      # fetch tools for whatever runs inside; language runtimes ship with the
      # agent that needs them
      environment.systemPackages = [
        pkgs.curl
        pkgs.git
      ];

      system.stateVersion = lib.versions.majorMinor lib.version;
    };
}
