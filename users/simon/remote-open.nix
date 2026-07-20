# open URLs sent by remote ssh/herdr sessions in the local browser. the
# workspace host forwards its /run/user/1000/remote-open.sock here via ssh
# RemoteForward (ssh.nix); the remote-open shim in users/workspace writes
# one URL per connection.
{ pkgs, ... }:
{
  systemd.user.sockets.remote-open = {
    Unit.Description = "remote xdg-open socket";
    Socket = {
      ListenStream = "%t/remote-open.sock";
      Accept = true;
    };
    Install.WantedBy = [ "sockets.target" ];
  };

  systemd.user.services."remote-open@" = {
    Unit.Description = "open remotely requested URL";
    Service = {
      StandardInput = "socket";
      ExecStart = toString (
        pkgs.writeShellScript "remote-open-handler" ''
          read -r line || exit 0
          case "$line" in
            http://* | https://*) exec ${pkgs.xdg-utils}/bin/xdg-open "$line" ;;
            "file "*)
              # workspace shim streams file content after this header; the
              # named file only exists on the remote host, so open a local copy
              name=''${line#file }
              case "$name" in
                */* | .* | "" | *.desktop)
                  echo "remote-open: refusing file name: $name" >&2
                  exit 1
                  ;;
              esac
              dir=$(${pkgs.coreutils}/bin/mktemp -d -t remote-open.XXXXXX)
              ${pkgs.coreutils}/bin/cat > "$dir/$name"
              exec ${pkgs.xdg-utils}/bin/xdg-open "$dir/$name"
              ;;
            *)
              echo "remote-open: refusing non-http url: $line" >&2
              exit 1
              ;;
          esac
        ''
      );
    };
  };
}
