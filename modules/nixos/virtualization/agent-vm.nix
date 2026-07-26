{ inputs, ... }:
{
  # a sealed microvm to run agents in. it provides the environment — private
  # bridge, nat to the internet, a firewall that drops every private range, a
  # persistent /var/lib and room to install into — and knows nothing about
  # which agent runs there. a machine says what to put inside:
  #
  #   nixfiles.agentVm.services = [ self.modules.nixos.hermesAgent ];
  flake.modules.nixos.agentVm =
    {
      config,
      flake-self,
      lib,
      self,
      ...
    }:
    let
      cfg = config.nixfiles.agentVm;
      # this host's sshd key, doubling as root's client identity into the vm.
      # the vm has no clan config of its own, so resolve the public half here
      # and hand it over. rotating this host's key locks root out of the vm
      # until the next deploy
      hostKey = config.clan.core.vars.generators.openssh.files."ssh.id_ed25519";
      adminKey = lib.trim (
        inputs.clan-core.clanLib.getPublicValue {
          flake = config.clan.core.settings.directory;
          machine = config.clan.core.settings.machine.name;
          generator = "openssh";
          file = "ssh.id_ed25519.pub";
        }
      );
    in
    {
      imports = [ inputs.microvm.nixosModules.host ];

      options.nixfiles.agentVm = {
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
          default = 2048;
          description = "memory handed to the vm, ballooned back when idle.";
        };
        memoryMax = lib.mkOption {
          type = lib.types.str;
          default = "4G";
          description = "hard cap on the whole vm, enforced by the host unit.";
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

        bridge = lib.mkOption {
          type = lib.types.str;
          default = "agentbr0";
        };
        hostIp = lib.mkOption {
          type = lib.types.str;
          default = "10.20.1.1";
          description = "the host's address on the bridge, and the vm's gateway.";
        };
        ip = lib.mkOption {
          type = lib.types.str;
          default = "10.20.1.2";
        };
        prefixLength = lib.mkOption {
          type = lib.types.int;
          default = 24;
        };
        dns = lib.mkOption {
          type = lib.types.str;
          default = builtins.head config.networking.nameservers;
          defaultText = "the host's first resolver";
        };
      };

      config = {
        # root on the host is the only thing that can reach the bridge, so
        # `ssh agent-vm` from the host logs in as root
        programs.ssh.extraConfig = ''
          Host agent-vm ${cfg.ip}
            HostName ${cfg.ip}
            User root
            IdentityFile ${hostKey.path}
            IdentitiesOnly yes
            StrictHostKeyChecking accept-new
        '';

        systemd.services.agent-vm-secrets = lib.mkIf (cfg.secrets != { }) {
          description = "stage secrets for the agent vm";
          wantedBy = [ "microvm@agent-vm.service" ];
          before = [ "microvm@agent-vm.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            install -d -m 0700 /var/lib/agent-vm
            install -d -m 0755 /var/lib/agent-vm/secrets
            ${lib.concatStringsSep "\n" (
              lib.mapAttrsToList (
                name: src: "install -m 0444 ${src} /var/lib/agent-vm/secrets/${name}"
              ) cfg.secrets
            )}
          '';
        };

        microvm.vms.agent-vm = {
          autostart = true;
          specialArgs = {
            inherit flake-self inputs self;
            agentVm = cfg // {
              inherit adminKey;
              hasSecrets = cfg.secrets != { };
              tap = "vma0";
              vsockCid = 3;
            };
          };
          config =
            { ... }:
            {
              imports = [ self.modules.nixos.agentVmBase ] ++ cfg.services;
            };
        };

        # the vm cannot outgrow this even if an agent misbehaves; the in-vm
        # balloon hands unused memory back below the cap
        systemd.services."microvm@agent-vm".serviceConfig = {
          MemoryMax = cfg.memoryMax;
          CPUQuota = cfg.cpuQuota;
          CPUWeight = 20;
        };

        networking.nat = {
          enable = true;
          externalInterface = "bond0";
          internalInterfaces = [ cfg.bridge ];
        };

        systemd.network = {
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
          networks."11-vma0" = {
            matchConfig.Name = "vma0";
            networkConfig.Bridge = cfg.bridge;
          };
        };

        networking.firewall = {
          # caddy fronts everything a local agent consumes and runs on this
          # host, so the one reachable service points at ourselves rather than
          # across the lan
          interfaces.${cfg.bridge}.allowedTCPPorts = [ 443 ];

          filterForward = true;
          # internet stays open; every private range is dropped, so a
          # compromised agent cannot walk the lan or the netbird mesh
          extraForwardRules = ''
            iifname "${cfg.bridge}" ip daddr ${cfg.dns} udp dport 53 accept
            iifname "${cfg.bridge}" ip daddr ${cfg.dns} tcp dport 53 accept
            iifname "${cfg.bridge}" ip daddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 100.64.0.0/10 } drop
            iifname "${cfg.bridge}" accept
            oifname "${cfg.bridge}" ct state established,related accept
          '';
        };
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
            mac = "02:00:00:00:20:01";
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
          source = "/var/lib/agent-vm/secrets";
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
        matchConfig.MACAddress = "02:00:00:00:20:01";
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

      # an agent that wants to install things at runtime should find the usual
      # tools already here
      environment.systemPackages = [
        pkgs.curl
        pkgs.git
        pkgs.nodejs
        pkgs.python3
      ];

      system.stateVersion = lib.versions.majorMinor lib.version;
    };
}
