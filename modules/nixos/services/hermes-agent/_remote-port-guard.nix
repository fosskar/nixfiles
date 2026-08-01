{ pkgs }:
pkgs.writeShellApplication {
  name = "hermes-remote-port-guard";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.gawk
  ];
  text = ''
    if [ "$#" -ne 2 ]; then
      echo "usage: hermes-remote-port-guard <port> <pid>" >&2
      exit 1
    fi
    port=$1
    pid=$2

    if [ ! -r /proc/net/tcp ]; then
      echo "hermes-remote-port-guard: cannot read /proc/net/tcp" >&2
      exit 1
    fi

    hexPort=$(printf '%04X' "$port")
    serving='00000000 0100007F 00000000000000000000000000000000 00000000000000000000FFFF0100007F'

    netFiles=(/proc/net/tcp)
    if [ -r /proc/net/tcp6 ]; then
      netFiles+=(/proc/net/tcp6)
    fi

    listeners=$(awk -v want="$hexPort" -v serving="$serving" '
      BEGIN { n = split(serving, a, " "); for (i = 1; i <= n; i++) ok[a[i]] = 1 }
      $4 == "0A" && split($2, p, ":") == 2 && (p[2] "") == (want "") && (p[1] in ok) { print $10, $8 }
    ' "''${netFiles[@]}")

    if [ -z "$listeners" ]; then
      exit 1
    fi

    held=""
    if [ -d "/proc/$pid/fd" ]; then
      for fd in "/proc/$pid/fd"/*; do
        if target=$(readlink "$fd" 2>/dev/null); then
          held="$held $target"
        fi
      done
    fi

    rc=0
    while read -r inode uid; do
      case "$held" in
      *"socket:[$inode]"*) ;;
      *)
        echo "hermes-remote-port-guard: 127.0.0.1:$port is held by a socket of uid $uid that pid $pid does not own" >&2
        rc=2
        ;;
      esac
    done <<< "$listeners"
    exit "$rc"
  '';
}
