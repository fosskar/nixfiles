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
  # the instance's id, so instances never collide.
  flake.modules.nixos.agentVm =
    {
      config,
      flake-self,
      lib,
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
      forEachInstance = f: lib.mkMerge (lib.mapAttrsToList f instances);
    in
    {
      imports = [ inputs.microvm.nixosModules.host ];

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

                stateSize = lib.mkOption {
                  type = lib.types.int;
                  default = 16384;
                  description = "size of the volume backing /var/lib inside the vm.";
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

            # the vm cannot outgrow this even if an agent misbehaves; the in-vm
            # balloon hands unused memory back below the cap
            "microvm@${name}".serviceConfig = {
              MemoryMax = cfg.memoryMax;
              CPUQuota = cfg.cpuQuota;
              CPUWeight = 20;
            };
          }) instances
        );

        microvm.vms = lib.mapAttrs (name: cfg: {
          autostart = true;
          specialArgs = {
            inherit flake-self inputs self;
            agentVm = cfg // {
              inherit adminKey name;
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
      agentVm,
      lib,
      pkgs,
      ...
    }:
    {
      microvm = {
        hypervisor = "cloud-hypervisor";
        inherit (agentVm) vcpu mem;
        balloon = true;
        deflateOnOOM = true;
        # cloud-hypervisor reports readiness over vsock; without a cid the host
        # unit only knows the process started, not that the vm came up
        vsock.cid = agentVm.vsockCid;

        interfaces = [
          {
            type = "tap";
            id = agentVm.tap;
            inherit (agentVm) mac;
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
        ++ lib.optional agentVm.hasSecrets {
          source = "/var/lib/agent-vm/${agentVm.name}/secrets";
          mountPoint = "/run/agent-secrets";
          tag = "secrets";
          proto = "virtiofs";
        };

        # every agent keeps its state under /var/lib, so back the whole tree
        # rather than making each one declare a directory
        volumes = [
          {
            image = "agent-vm-state.img";
            label = "agent-state";
            mountPoint = "/var/lib";
            size = agentVm.stateSize;
          }
        ];
      };

      networking = {
        useDHCP = false;
        useNetworkd = true;
        firewall.enable = true;
      };

      # virtio gives unpredictable enp0sN names, so match the mac we assigned.
      # v4 only: no RA-assigned v6 for the host's v4 forward rules to miss
      systemd.network.networks."10-lan" = {
        matchConfig.MACAddress = agentVm.mac;
        networkConfig = {
          Address = "${agentVm.ip}/${toString agentVm.prefixLength}";
          Gateway = agentVm.hostIp;
          DNS = agentVm.dns;
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

      users.users.root.openssh.authorizedKeys.keys = [ agentVm.adminKey ];

      # fetch tools for whatever runs inside; language runtimes ship with the
      # agent that needs them
      environment.systemPackages = [
        pkgs.curl
        pkgs.git
      ];

      system.stateVersion = lib.versions.majorMinor lib.version;
    };
}
