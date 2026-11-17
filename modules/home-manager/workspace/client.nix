# workstation side of the nixworker workspace: ssh hosts, the relay that
# forwards local agents and the browser socket, and its resume restart.
# the host side is host.nix
_: {
  # user units cannot order after suspend.target; reconnect right after wake
  # instead of waiting for ServerAlive to declare the old connection dead
  flake.modules.nixos.workspaceClient =
    { pkgs, ... }:
    {
      systemd.services.workspace-relay-resume =
        let
          sleepTargets = [
            "suspend.target"
            "hibernate.target"
            "hybrid-sleep.target"
            "suspend-then-hibernate.target"
          ];
        in
        {
          description = "Restart simon's workspace-relay after resume";
          after = sleepTargets;
          wantedBy = sleepTargets;
          unitConfig.ConditionPathExists = "/run/user/1000/bus";
          serviceConfig.Type = "oneshot";
          script = "${pkgs.systemd}/bin/systemctl --user --machine=simon@ try-restart workspace-relay.service";
        };
    };

  flake.modules.homeManager.workspaceClient =
    {
      lib,
      options,
      pkgs,
      ...
    }:
    let
      ctl = "/run/user/1000/workspace-relay.ctl";
      ssh = lib.getExe pkgs.openssh;

      # name this client as the one the user sits at (host-socket-relay.nix):
      # links, gpg and ssh-agent requests from the workspace come here.
      # runs over the authenticated workspace-relay connection, so it never
      # asks the yubikey. --release drops the claim if this client holds it
      workspace-claim = pkgs.writeShellScriptBin "workspace-claim" ''
        set -eu
        host=$(${pkgs.coreutils}/bin/uname -n)
        f=/run/user/1000/fwd/active
        if [ "''${1:-}" = --release ]; then
          cmd="[ \"\$(cat $f 2>/dev/null)\" != $host ] || rm $f"
        else
          cmd="echo $host > $f.tmp && mv $f.tmp $f"
        fi
        if ! ${ssh} -S ${ctl} -O check workspace-relay 2>/dev/null; then
          echo "workspace-claim: no workspace-relay connection" >&2
          exit 1
        fi
        exec ${pkgs.coreutils}/bin/timeout 10 ${ssh} -S ${ctl} -o ControlMaster=no -o BatchMode=yes \
          -o ClearAllForwardings=yes -o SessionType=default workspace-relay sh -c "'$cmd'"
      '';
    in
    {
      config = lib.mkMerge [
        {
          home.packages = [ workspace-claim ];

          # per-client forward paths (%L = this client's hostname); the socket-relay
          # units on the workspace host (host-socket-relay.nix) fan the fixed
          # consumer paths out to the claimed or else newest live forward, so several clients can
          # stay attached at once: gpg-agent extra socket (clan update, sops
          # decrypt via local yubikey), the yubikey ssh agent (git push, ssh to
          # clan machines) and the remote-open browser socket
          programs.ssh.settings = {
            "workspace" = {
              HostName = "nixworker.s";
              User = "simon";
              ConnectTimeout = 5;
              ConnectionAttempts = 1;
              ForwardAgent = "yes";
              LocalForward = [ "54545 localhost:54545" ];
              ServerAliveInterval = 15;
              ServerAliveCountMax = 3;
            };
            "workspace-relay" = {
              HostName = "nixworker.s";
              User = "simon";
              ConnectTimeout = 5;
              ConnectionAttempts = 1;
              # the relay is the master; workspace-claim runs over it
              ControlMaster = "auto";
              ControlPath = ctl;
              # the global ControlPersist would fork the master into the background;
              # systemd then sees ExecStart exit and kills the connection
              ControlPersist = "no";
              ExitOnForwardFailure = "yes";
              SessionType = "none";
              ServerAliveInterval = 5;
              ServerAliveCountMax = 3;
              RemoteForward = [
                "/run/user/1000/fwd/%L.gpg-extra /run/user/1000/gnupg/S.gpg-agent.extra"
                "/run/user/1000/fwd/%L.ssh-agent /run/user/1000/gnupg/S.gpg-agent.ssh"
                "/run/user/1000/fwd/%L.remote-open /run/user/1000/remote-open.sock"
              ];
            };
          };

          systemd.user.services.workspace-relay = {
            Unit = {
              Description = "forward local agents to the workspace";
              After = [ "network-online.target" ];
              Wants = [ "network-online.target" ];
            };
            Service = {
              # a killed master leaves its control socket behind, and auto would then
              # run without multiplexing
              ExecStartPre = "${pkgs.coreutils}/bin/rm -f ${ctl}";
              ExecStart = "${ssh} -NT workspace-relay";
              Restart = "always";
              RestartSec = 10;
              # back off to 5 min while nixworker is unreachable; the resume restart
              # above resets the counter, so wake-up still reconnects at once
              RestartSteps = 5;
              RestartMaxDelaySec = 300;
            };
            Install.WantedBy = [ "default.target" ];
          };
        }
        (lib.optionalAttrs (options.programs ? noctalia) {
          # unlocking a machine claims the workspace for it; locking releases it
          programs.noctalia.settings.hooks = {
            started = lib.getExe workspace-claim;
            session_unlocked = lib.getExe workspace-claim;
            session_locked = "${lib.getExe workspace-claim} --release";
          };
        })
      ];
    };
}
