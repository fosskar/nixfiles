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
          read -r url || exit 0
          case "$url" in
            http://* | https://*) exec ${pkgs.xdg-utils}/bin/xdg-open "$url" ;;
            *)
              echo "remote-open: refusing non-http url: $url" >&2
              exit 1
              ;;
          esac
        ''
      );
    };
  };
}
