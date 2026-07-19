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
      # dead forwards (client gone, socket file left behind) fail the probe
      # connect instantly and fall through to the next candidate.
      for s in $(${pkgs.coreutils}/bin/ls -t "$XDG_RUNTIME_DIR"/fwd/*.${name} 2>/dev/null); do
        if ${pkgs.socat}/bin/socat -u OPEN:/dev/null UNIX-CONNECT:"$s" 2>/dev/null; then
          exec ${pkgs.socat}/bin/socat STDIO UNIX-CONNECT:"$s"
        fi
      done
      echo "socket-relay-${name}: no live client forward" >&2
      exit 1
    '';
in
{
  systemd.user.tmpfiles.rules = [ "d %t/fwd 0700 - - -" ];

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
