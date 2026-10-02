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
    { pkgs, ... }:
    {
      # per-client forward paths (%L = this client's hostname); the socket-relay
      # units on the workspace host (host-socket-relay.nix) fan the fixed
      # consumer paths out to the newest live forward, so several clients can
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
          ControlMaster = "no";
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
          ExecStart = "${pkgs.openssh}/bin/ssh -NT workspace-relay";
          Restart = "always";
          RestartSec = 10;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
