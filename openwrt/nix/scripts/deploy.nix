# deploy script — applies packages, UCI config, SSH keys, and files to a device
{
  pkgs,
  lib,
  devices,
  deviceNames,
  uciOutputs,
}:
pkgs.writeShellScriptBin "openwrt-deploy" ''
  set -euo pipefail

  usage() {
    echo "usage: openwrt-deploy <device> [--dry-run|-n]"
    echo ""
    echo "devices: ${deviceNames}"
    exit 1
  }

  [ $# -lt 1 ] && usage

  DEVICE="$1"; shift
  DRY_RUN=false
  for arg in "$@"; do
    case "$arg" in
      --dry-run|-n) DRY_RUN=true ;;
      --help|-h) usage ;;
      *) echo "unknown arg: $arg"; usage ;;
    esac
  done

  case "$DEVICE" in
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: device:
        let
          uci = uciOutputs.${name};
          autoReload = builtins.attrNames device.uci.settings;
          allReload = lib.unique (autoReload ++ (device.reload or [ ]));
          reloadList = lib.concatMapStringsSep " " lib.escapeShellArg allReload;
          hasKeys = device.authorizedKeys != [ ];
          keysFile = pkgs.writeText "authorized_keys-${name}" (
            lib.concatStringsSep "\n" device.authorizedKeys + "\n"
          );
          hasPackages = device.packages != [ ];
          packageList = lib.concatStringsSep " " device.packages;
          hasRemove = device.removePackages != [ ];
          removeList = lib.concatStringsSep " " device.removePackages;
          hasDisable = device.disableServices != [ ];
          disableList = lib.concatStringsSep " " device.disableServices;
          hasFiles = device.files != { };
        in
        ''
          ${name})
            HOST="root@${device.host}"
            RELOAD_SERVICES=(${reloadList})
            commands=$(${uci.command})

            if $DRY_RUN; then
              ${lib.optionalString hasPackages ''
                echo "# packages: ${packageList}"
                echo ""
              ''}
              echo "# UCI batch commands for ${name} ($HOST)"
              echo "$commands"
              ${lib.optionalString hasKeys ''
                echo ""
                echo "# SSH authorized keys:"
                cat "${keysFile}"
              ''}
              ${lib.optionalString hasFiles ''
                echo ""
                echo "# files:"
                ${lib.concatStringsSep "\n" (
                  lib.mapAttrsToList (remote: local: ''
                    echo "  ${remote} <- ${local}"
                  '') device.files
                )}
              ''}
              exit 0
            fi

            echo "deploying ${name} to $HOST..."

            ${lib.optionalString hasPackages ''
              ${lib.optionalString hasRemove ''
                ssh -o ConnectTimeout=5 "$HOST" "apk del -q ${removeList}" 2>/dev/null || true
              ''}
              ssh -o ConnectTimeout=5 "$HOST" "apk add -q ${packageList}" 2>/dev/null
            ''}

            ${lib.optionalString hasDisable ''
              for svc in ${disableList}; do
                ssh -o ConnectTimeout=5 "$HOST" "/etc/init.d/$svc disable 2>/dev/null; /etc/init.d/$svc stop 2>/dev/null" || true
              done
              ${lib.optionalString (builtins.elem "firewall" device.disableServices) ''
                ssh "$HOST" 'nft flush ruleset 2>/dev/null' || true
              ''}
            ''}

            # snapshot current config for sections we manage
            managed_cfgs="${lib.concatStringsSep " " (builtins.attrNames device.uci.settings)}"
            before=$(ssh -o ConnectTimeout=5 "$HOST" "for cfg in $managed_cfgs; do uci show \$cfg 2>/dev/null; done" || true)

            echo "$commands" | ssh "$HOST" 'uci -q batch' >/dev/null 2>&1

            after=$(ssh "$HOST" "for cfg in $managed_cfgs; do uci show \$cfg 2>/dev/null; done" || true)

            if [ "$before" = "$after" ]; then
              echo "no changes."
            else
              echo "committing..."
              ssh "$HOST" 'uci commit'

              for cfg in $managed_cfgs; do
                cfg_before=$(echo "$before" | grep "^$cfg\." || true)
                cfg_after=$(echo "$after" | grep "^$cfg\." || true)
                if [ "$cfg_before" != "$cfg_after" ]; then
                  echo "reloading $cfg..."
                  ssh "$HOST" "/etc/init.d/$cfg reload 2>/dev/null || /etc/init.d/$cfg restart 2>/dev/null || true"
                fi
              done
            fi

            ${lib.optionalString hasKeys ''
              current_keys=$(ssh "$HOST" 'cat /etc/dropbear/authorized_keys 2>/dev/null' || true)
              new_keys=$(cat "${keysFile}")
              if [ "$current_keys" != "$new_keys" ]; then
                echo "installing SSH keys..."
                ssh "$HOST" 'mkdir -p /etc/dropbear && umask 177 && cat > /etc/dropbear/authorized_keys' < "${keysFile}"
              fi
            ''}

            ${lib.optionalString hasFiles (
              lib.concatStringsSep "\n" (
                lib.mapAttrsToList (remote: local: ''
                  current_file=$(ssh "$HOST" 'cat ${remote} 2>/dev/null' || true)
                  new_file=$(cat "${local}")
                  if [ "$current_file" != "$new_file" ]; then
                    echo "pushing ${remote}..."
                    ssh "$HOST" 'mkdir -p $(dirname ${remote}) && cat > ${remote}' < "${local}"
                  fi
                '') device.files
              )
            )}

            echo "done."
            ;;
        ''
      ) devices
    )}
    *) echo "unknown device: $DEVICE"; echo "available: ${deviceNames}"; exit 1 ;;
  esac
''
