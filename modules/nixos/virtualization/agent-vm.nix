{ inputs, ... }:
{
  # compat adapter over fencr: nixfiles.agentVms keeps its shape for the
  # clan services, fencr.vms provides the sealed microvm. nixfiles adds
  # what fencr deliberately left behind: clan-sourced admin identity,
  # the backup quiesce hook, and the caddy bridge pinhole default.
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
      instances = config.nixfiles.agentVms;
      hostKey = config.clan.core.vars.generators.openssh.files."ssh.id_ed25519";
      adminKey = lib.trim (
        inputs.clan-core.clanLib.getPublicValue {
          flake = config.clan.core.settings.directory;
          machine = config.clan.core.settings.machine.name;
          generator = "openssh";
          file = "ssh.id_ed25519.pub";
        }
      );
      resourceKeys = [
        "egress"
        "vcpu"
        "mem"
        "memoryMax"
        "cpuQuota"
        "dns"
      ];
      forwardLib = import ./_forwards.nix { inherit lib; };
      forwardsOf = cfg: map (forward: { listenAddress = "127.0.0.1"; } // forward) (cfg.forwards or [ ]);
      toFencr =
        cfg:
        {
          inherit (cfg) id services secrets;
          allowedTCPDestinations = cfg.allowedTCPDestinations or [ ];
          expose = map (forward: forward.guestPort) (forwardsOf cfg);
          credentials = cfg.credentials or [ ];
          # caddy fronts everything a local agent consumes and runs on the
          # host, so the reachable host service points at ourselves
          hostPorts = [
            80
            443
          ];
          specialArgs = {
            inherit flake-self inputs self;
          };
        }
        // lib.filterAttrs (name: _: lib.elem name resourceKeys) cfg;
    in
    {
      imports = [
        inputs.fencr.nixosModules.fencr
        self.modules.nixos.agentForwards
      ];

      options.nixfiles.agentVms = lib.mkOption {
        default = { };
        description = "sealed agent microvms, keyed by vm name; adapter over fencr.vms.";
        type = lib.types.attrsOf lib.types.raw;
      };

      config = {
        fencr.vms = lib.mapAttrs (_: toFencr) instances;
        fencr.adminKeys = [ adminKey ];

        nixfiles.agentForwardEndpoints = forwardLib.endpointsOf (
          lib.mapAttrs (_: cfg: { forwards = forwardsOf cfg; }) instances
        );

        # a forward is a host loopback listener relayed to the guest's address,
        # the same shape as the container's; fencr itself only opens the port
        systemd.services = lib.mkMerge (
          lib.mapAttrsToList (
            name: cfg:
            lib.listToAttrs (
              map (forward: {
                name = "${forwardLib.unitName name forward}@";
                value = {
                  description = "forward to ${name} guest port ${toString forward.guestPort}";
                  after = [ "fencr-${name}.service" ];
                  requisite = [ "fencr-${name}.service" ];
                  unitConfig.CollectMode = "inactive-or-failed";
                  serviceConfig = forwardLib.hardening config.fencr.vms.${name}.ip // {
                    ExecStart = "${pkgs.socat}/bin/socat STDIO TCP:${config.fencr.vms.${name}.ip}:${toString forward.guestPort}";
                  };
                };
              }) (forwardsOf cfg)
            )
          ) instances
        );

        systemd.sockets = lib.mkMerge (
          lib.mapAttrsToList (
            name: cfg:
            lib.listToAttrs (
              map (forward: {
                name = forwardLib.unitName name forward;
                value = {
                  description = "forward to ${name} guest port ${toString forward.guestPort}";
                  wantedBy = [ "sockets.target" ];
                  listenStreams = [ "${forward.listenAddress}:${toString forward.listenPort}" ];
                  socketConfig = {
                    Accept = true;
                    MaxConnections = 64;
                  };
                };
              }) (forwardsOf cfg)
            )
          ) instances
        );

        # root's client identity into the vms stays the host's sshd key, so
        # non-interactive root sessions keep working; fencr's alias block
        # only sets the transport and IdentityFile accumulates across blocks
        programs.ssh.extraConfig = lib.mkAfter (
          lib.concatStrings (
            lib.mapAttrsToList (name: _: ''
              Host ${name}
                IdentityFile ${hostKey.path}
            '') instances
          )
        );

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
              lib.concatMapStringsSep " " (name: "fencr-${name}.service") (lib.attrNames instances)
            }; do
              if systemctl is-active --quiet "$unit"; then
                active="$active $unit"
              fi
            done
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
            rsync -a --delete /var/lib/fencr-vms/ /var/backup/agent-vms/
          '';
        };
      };
    };
}
