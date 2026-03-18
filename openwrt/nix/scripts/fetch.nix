# fetch script — dumps current UCI config from a device
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
          echo "# current UCI config from ${name} ($HOST)"
          echo "# use this to populate openwrt/devices/${name}/config.nix"
          echo ""
          ssh -o ConnectTimeout=5 "$HOST" '
            for f in /etc/config/*; do
              cfg=$(basename "$f")
              echo "--- $cfg ---"
              uci show "$cfg" 2>/dev/null || true
              echo ""
            done
          '
          ;;
      '') devices
    )}
    *) echo "unknown device: $DEVICE"; echo "available: ${deviceNames}"; exit 1 ;;
  esac
''
