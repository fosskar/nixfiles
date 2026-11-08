# fetch script: prints the device's changes from factory defaults as nix for uci.settings
{
  pkgs,
  lib,
  devices,
  deviceNames,
}:
pkgs.writeShellApplication {
  name = "openwrt-fetch";
  runtimeInputs = [
    pkgs.nix
    pkgs.nixfmt
    pkgs.openssh
  ];
  text = ''
    usage() {
      echo "usage: openwrt-fetch <device> [config...]"
      echo ""
      echo "prints sections that differ from factory defaults as { settings; delete; }"
      echo "devices: ${deviceNames}"
      exit 1
    }

    [ $# -lt 1 ] && usage

    DEVICE="$1"; shift

    case "$DEVICE" in
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: device: ''
          ${name}) HOST=${lib.escapeShellArg "root@${device.host}"} ;;
        '') devices
      )}
      *) echo "unknown device: $DEVICE"; echo "available: ${deviceNames}"; exit 1 ;;
    esac

    json=$(mktemp)
    trap 'rm -f "$json"' EXIT
    # shellcheck disable=SC2029 # config names expand locally on purpose
    ssh -o ConnectTimeout=5 "$HOST" ucode - "$@" < ${../fetch.uc} > "$json"
    nix-instantiate --eval --strict --expr "builtins.fromJSON (builtins.readFile $json)" | nixfmt
  '';
}
