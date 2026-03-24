# diff script — shows drift between nix-declared config and current router state
{
  pkgs,
  lib,
  devices,
  deviceNames,
  uciOutputs,
}:
pkgs.writeShellScriptBin "openwrt-diff" ''
  set -euo pipefail

  usage() {
    echo "usage: openwrt-diff <device>"
    echo ""
    echo "shows drift: nix config vs current router state"
    echo "devices: ${deviceNames}"
    exit 1
  }

  [ $# -lt 1 ] && usage

  DEVICE="$1"; shift

  case "$DEVICE" in
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: device:
        let
          uci = uciOutputs.${name};
          managedCfgs = builtins.attrNames device.uci.settings;
          cfgList = lib.concatStringsSep " " managedCfgs;
        in
        ''
          ${name})
            HOST="root@${device.host}"
            commands=$(${uci.command})

            # get current committed state for managed configs
            current=$(ssh -o ConnectTimeout=5 "$HOST" '
              for cfg in ${cfgList}; do
                uci show "$cfg" 2>/dev/null
              done
            ' | sort)

            # apply batch to staging, read result, then revert
            desired=$(echo "$commands" | ssh "$HOST" '
              uci -q batch >/dev/null 2>&1
              for cfg in ${cfgList}; do
                uci show "$cfg" 2>/dev/null
              done
              for cfg in ${cfgList}; do
                uci revert "$cfg" 2>/dev/null
              done
            ' | sort)

            if [ "$current" = "$desired" ]; then
              echo "no drift — ${name} matches nix config"
            else
              echo "# drift on ${name} ($HOST)"
              echo "# < current router state"
              echo "# > nix-declared config"
              echo ""
              ${lib.getExe' pkgs.diffutils "diff"} <(echo "$current") <(echo "$desired") \
                --unified=0 --color=always \
                --label "router" --label "nix" \
                || true
            fi
            ;;
        ''
      ) devices
    )}
    *) echo "unknown device: $DEVICE"; echo "available: ${deviceNames}"; exit 1 ;;
  esac
''
