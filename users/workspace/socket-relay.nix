# multiplex per-client RemoteForward sockets behind the fixed paths consumers
# use. each attached client forwards its sockets to $XDG_RUNTIME_DIR/fwd/
# <hostname>.<name> (users/simon/ssh.nix); every connection to a fixed path is
# relayed to the newest still-live forward. desktop and laptop can stay
# attached simultaneously; a forgotten session on one never blocks the other.
{ pkgs, lib, ... }:
let
  # relay name -> fixed socket path (relative to $XDG_RUNTIME_DIR) consumers
  # connect to: gpg (sops, clan update), ssh (git push, clan ssh), remote-open
  relays = {
    gpg-extra = "gnupg/S.gpg-agent";
    ssh-agent = "ssh-agent.sock";
    remote-open = "remote-open.sock";
  };
  relayScript =
    name:
    pkgs.writeShellScript "socket-relay-${name}" ''
      # newest forward first: the client attached last is where the user sits.
      # a connect-only probe cannot see a half-dead ssh connection (suspended
      # laptop, roamed wifi): sshd still accepts on the forward socket and the
      # relay would hang forever. instead demand a real agent reply from the
      # client's ssh-agent forward; all forwards of one client share the same
      # ssh connection, so agent liveness vouches for the other sockets too.
      # ssh-add exits 1 when the agent answers "no identities"; still live.
      for s in $(${pkgs.coreutils}/bin/ls -t "$XDG_RUNTIME_DIR"/fwd/*.${name} 2>/dev/null); do
        agent="''${s%.${name}}.ssh-agent"
        SSH_AUTH_SOCK="$agent" ${pkgs.coreutils}/bin/timeout 2 ${pkgs.openssh}/bin/ssh-add -l >/dev/null 2>&1
        case $? in
          0 | 1) exec ${pkgs.socat}/bin/socat STDIO UNIX-CONNECT:"$s" ;;
        esac
      done
      echo "socket-relay-${name}: no live client forward" >&2
      exit 1
    '';
in
{
  # gnupg requires its socketdir to be mode 0700; when the gpg-extra relay
  # socket creates %t/gnupg first, systemd's default 0755 makes gpg silently
  # fall back to ~/.gnupg/S.gpg-agent and autostart an empty local agent
  systemd.user.tmpfiles.rules = [
    "d %t/fwd 0700 - - -"
    "d %t/gnupg 0700 - - -"
  ];

  systemd.user.sockets = lib.mapAttrs' (
    name: path:
    lib.nameValuePair "socket-relay-${name}" {
      Unit.Description = "relay socket for per-client ${name} forwards";
      Socket = {
        ListenStream = "%t/${path}";
        Accept = true;
      };
      Install.WantedBy = [ "sockets.target" ];
    }
  ) relays;

  systemd.user.services = lib.mapAttrs' (
    name: _:
    lib.nameValuePair "socket-relay-${name}@" {
      Unit.Description = "relay connection to newest live ${name} forward";
      Service = {
        StandardInput = "socket";
        StandardOutput = "socket";
        ExecStart = toString (relayScript name);
      };
    }
  ) relays;
}
