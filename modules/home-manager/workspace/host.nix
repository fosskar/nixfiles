# nixworker side of the workspace: the dev user reaches the attached
# client's gpg and ssh agents and its browser through the forwarded sockets
# (client.nix), fanned out by host-socket-relay.nix
_: {
  flake.modules.nixos.workspaceHost = {
    # let a reconnecting client's RemoteForward replace its own stale per-client
    # socket under %t/fwd (client.nix)
    services.openssh.settings.StreamLocalBindUnlink = true;

    # simon's yubikey pubkeys (same shared generator as modules/nixos/hardware/yubikey/gpg-ssh.nix)
    clan.core.vars.generators.yubikey = {
      share = true;
      files = {
        "gpg-pubkey.asc".secret = false;
        "id_yubikey.pub".secret = false;
      };
      script = "true";
    };

    programs.gnupg.agent.enable = false;
  };

  flake.modules.homeManager.workspaceHost = {
    home.sessionVariables.BROWSER = "remote-open";

    # exported in shellInit, not sessionVariables: herdr panes are non-login
    # shells and never source hm-session-vars. SSH_AUTH_SOCK = socket-relay
    # fan-out over the per-client forwarded yubikey agents
    programs.fish.shellInit = ''
      set -gx SSH_AUTH_SOCK /run/user/1000/ssh-agent.sock
      set -gx BROWSER remote-open
    '';
  };
}
