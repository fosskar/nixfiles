{
  flake.modules.nixos.tern =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.local.tern ];

      # tern updates its copy in ~/.local/opt/tern, so the unpatched binary runs through nix-ld
      programs.nix-ld.enable = true;
      # libraries the binary dlopens at runtime
      programs.nix-ld.libraries = [
        pkgs.libglvnd
        pkgs.vulkan-loader
        pkgs.wayland
        pkgs.libxkbcommon
        pkgs.libxcb
        pkgs.libpulseaudio
        pkgs.pipewire
        pkgs.webkitgtk_4_1
        pkgs.linux-pam
      ];
    };

  # clients reach homeManager.ternServer on the lan; tern 0.9.7 rejects ipv6 addresses ("invalid remote address"), so they dial 192.168.20.210
  flake.modules.nixos.ternServer = {
    networking.firewall.allowedUDPPorts = [ 8376 ];
  };

  # serves this user's sessions to tern windows on other machines over UDP 8376
  # ([::]), or by endpoint id over the iroh.stencil.so relay.
  # host key and endpoint id: tern remote host-key --user
  flake.modules.homeManager.ternServer =
    { pkgs, ... }:
    let
      # a login needs the client's key in authorized_keys and a rule here
      access = pkgs.writeText "tern-access.toml" ''
        [[allow]]
        method = "ssh-key"
        identity = "*"
        users = ["simon"]
      '';
    in
    {
      systemd.user.services.tern-remote = {
        Unit.Description = "Tern remote sessions";
        Service = {
          Type = "exec";
          # nixos keeps authorized_keys in /etc/ssh/authorized_keys.d, not ~/.ssh
          ExecStart = "${pkgs.local.tern}/bin/tern remote serve --user --access ${access} --authorized-keys /etc/ssh/authorized_keys.d/%u";
          WorkingDirectory = "%h";
          # home-manager user units get no PATH; the session daemon's shells inherit this environment
          Environment = [
            "PATH=/run/wrappers/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin"
            # the fish shellInit of workspaceHost sets these too; non-shell panes need them here
            "SSH_AUTH_SOCK=%t/ssh-agent.sock"
            "BROWSER=remote-open"
          ];
          Restart = "on-failure";
          RestartSec = 2;
          # exit status 2 is bad arguments
          RestartPreventExitStatus = 2;
          # session daemons outlive the service, as tmux outlives sshd
          KillMode = "process";
          TimeoutStopSec = 10;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
