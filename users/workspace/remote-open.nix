# forward browser-open requests to the attached ssh client: agent logins
# (claude, gh auth, ...) call $BROWSER or xdg-open, the URL travels through
# the RemoteForward socket (users/simon/ssh.nix) and opens on the
# desktop/laptop that is currently attached via ssh or herdr --remote.
{ pkgs, lib, ... }:
let
  remote-open = pkgs.writeShellScriptBin "remote-open" ''
    rt="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
    # the relay socket (users/workspace/socket-relay.nix) always exists; check
    # for an actual client forward so "no client attached" stays visible here
    if ${pkgs.coreutils}/bin/ls "$rt"/fwd/*.remote-open >/dev/null 2>&1; then
      printf '%s\n' "$1" | ${pkgs.socat}/bin/socat - "UNIX-CONNECT:$rt/remote-open.sock"
    else
      echo "remote-open: no forwarded client socket; open manually: $1" >&2
      exit 1
    fi
  '';
in
{
  home.packages = [
    remote-open
    # agents that ignore $BROWSER shell out to xdg-open; same path
    (pkgs.writeShellScriptBin "xdg-open" ''exec ${lib.getExe remote-open} "$@"'')
  ];
}
