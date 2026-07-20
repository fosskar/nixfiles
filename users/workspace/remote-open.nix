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
    if ! ${pkgs.coreutils}/bin/ls "$rt"/fwd/*.remote-open >/dev/null 2>&1; then
      echo "remote-open: no forwarded client socket; open manually: $1" >&2
      exit 1
    fi
    arg="$1"
    case "$arg" in
      file://*) path=''${arg#file://} ;;
      /* | ./* | ../*) path="$arg" ;;
      *) path= ;;
    esac
    if [ -n "$path" ]; then
      if [ ! -r "$path" ]; then
        echo "remote-open: cannot read file: $path" >&2
        exit 1
      fi
      # local file does not exist on the attached client; stream its content
      { printf 'file %s\n' "$(${pkgs.coreutils}/bin/basename "$path")"
        ${pkgs.coreutils}/bin/cat "$path"
      } | ${pkgs.socat}/bin/socat - "UNIX-CONNECT:$rt/remote-open.sock"
    else
      printf '%s\n' "$arg" | ${pkgs.socat}/bin/socat - "UNIX-CONNECT:$rt/remote-open.sock"
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
