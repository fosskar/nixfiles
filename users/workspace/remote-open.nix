# forward browser-open requests to the attached ssh client: agent logins
# (claude, gh auth, ...) call $BROWSER or xdg-open, the URL travels through
# the RemoteForward socket (users/simon/ssh.nix) and opens on the
# desktop/laptop that is currently attached via ssh or herdr --remote.
{ pkgs, lib, ... }:
let
  remote-open = pkgs.writeShellScriptBin "remote-open" ''
    sock="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}/remote-open.sock"
    if [ -S "$sock" ]; then
      printf '%s\n' "$1" | ${pkgs.socat}/bin/socat - "UNIX-CONNECT:$sock"
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
