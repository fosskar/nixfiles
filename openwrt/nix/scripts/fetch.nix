# fetch script — shows changes from factory defaults (/rom/etc/config/)
{
  pkgs,
  lib,
  devices,
  deviceNames,
}:
pkgs.writeShellScriptBin "openwrt-fetch" ''
  set -euo pipefail

  usage() {
    echo "usage: openwrt-fetch <device>"
    echo ""
    echo "shows changes from factory defaults"
    echo "devices: ${deviceNames}"
    exit 1
  }

  [ $# -lt 1 ] && usage

  DEVICE="$1"; shift

  case "$DEVICE" in
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: device: ''
            ${name})
              HOST="root@${device.host}"
              echo "# config diff from factory defaults on ${name} ($HOST)"
              echo ""
              ssh -o ConnectTimeout=5 "$HOST" '
                for f in /etc/config/*; do
                  cfg=$(basename "$f")
                  current=$(uci show "$cfg" 2>/dev/null)
                  default=$(uci -c /rom/etc/config show "$cfg" 2>/dev/null)
                  if [ "$current" != "$default" ]; then
                    changed=""
                    while IFS= read -r line; do
                      echo "$default" | grep -qxF "$line" || changed="$changed
        $line"
                    done <<EOF
        $current
        EOF
                    if [ -n "$changed" ]; then
                      echo "--- $cfg ---"
                      echo "$changed" | tail -n +2
                      echo ""
                    fi
                  fi
                done
              '
              ;;
      '') devices
    )}
    *) echo "unknown device: $DEVICE"; echo "available: ${deviceNames}"; exit 1 ;;
  esac
''
