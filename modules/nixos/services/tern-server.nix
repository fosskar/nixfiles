_: {
  # serves simon's sessions to tern windows on other machines over UDP 8376
  # ([::]), or by endpoint id over the iroh.stencil.so relay. clients on the lan
  # dial 192.168.20.210: tern 0.9.7 rejects ipv6 addresses ("invalid remote address").
  # host key and endpoint id: tern remote host-key --user
  flake.modules.nixos.ternServer =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      user = "simon";
      runtimeDir = "/run/user/${toString config.users.users.${user}.uid}";
      # a login needs the client's key in authorized_keys and a rule here
      access = pkgs.writeText "tern-access.toml" ''
        [[allow]]
        method = "ssh-key"
        identity = "*"
        users = ["${user}"]
      '';
    in
    {
      networking.firewall.allowedUDPPorts = [ 8376 ];

      # the user runtime dir holds the session daemon socket, which `tern` in the user's shells finds there
      users.users.${user}.linger = true;

      systemd.services.tern-remote = {
        description = "Tern remote sessions";
        wantedBy = [ "multi-user.target" ];
        requires = [ "user-runtime-dir@${toString config.users.users.${user}.uid}.service" ];
        after = [
          "network.target"
          "user-runtime-dir@${toString config.users.users.${user}.uid}.service"
        ];
        environment = {
          XDG_RUNTIME_DIR = runtimeDir;
          # the session daemon's shells inherit this environment; replaces the nixos default unit PATH
          PATH = lib.mkForce "/run/wrappers/bin:/etc/profiles/per-user/${user}/bin:/run/current-system/sw/bin";
          # the fish shellInit of workspaceHost sets these too; non-shell panes need them here
          SSH_AUTH_SOCK = "${runtimeDir}/ssh-agent.sock";
          BROWSER = "remote-open";
          # tern runs its self-updated copy in ~/.local/opt/tern through nix-ld
          NIX_LD_LIBRARY_PATH = "${lib.makeLibraryPath pkgs.local.tern.runtimeLibs}:/run/current-system/sw/share/nix-ld/lib";
        };
        serviceConfig = {
          Type = "exec";
          User = user;
          # nixos keeps authorized_keys in /etc/ssh/authorized_keys.d, not ~/.ssh
          ExecStart = "${pkgs.local.tern}/bin/tern remote serve --user --access ${access} --authorized-keys /etc/ssh/authorized_keys.d/${user}";
          WorkingDirectory = "~";
          Restart = "on-failure";
          RestartSec = 2;
          # exit status 2 is bad arguments
          RestartPreventExitStatus = 2;
          # session daemons outlive the service, as tmux outlives sshd
          KillMode = "process";
          TimeoutStopSec = 10;
        };
      };
    };
}
