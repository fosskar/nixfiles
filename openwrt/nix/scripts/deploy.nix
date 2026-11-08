# deploy script: renders apply.uc with secrets, runs it on the device, confirms the rollback
{
  pkgs,
  lib,
  devices,
  deviceNames,
  configJsons,
  render,
}:
pkgs.writeShellApplication {
  name = "openwrt-deploy";
  runtimeInputs = [
    render
    pkgs.age-plugin-yubikey
    pkgs.coreutils
    pkgs.gawk
    pkgs.jq
    pkgs.openssh
    pkgs.openssl
    pkgs.sops
  ];
  text = ''
    usage() {
      echo "usage: openwrt-deploy <device> [--dry-run|-n]"
      echo ""
      echo "devices: ${deviceNames}"
      exit 1
    }

    [ $# -lt 1 ] && usage

    DEVICE="$1"; shift
    MODE=apply
    for arg in "$@"; do
      case "$arg" in
        --dry-run|-n) MODE=plan ;;
        --help|-h) usage ;;
        *) echo "unknown arg: $arg"; usage ;;
      esac
    done

    case "$DEVICE" in
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: device: ''
          ${name})
            HOST=${lib.escapeShellArg "root@${device.host}"}
            CONFIG=${configJsons.${name}}
            SOPS_FILES=(${lib.escapeShellArgs device.uci.secrets.sops.files})
            PASSWORD_SECRET=${lib.escapeShellArg (toString device.rootPasswordSecret)}
            ;;
        '') devices
      )}
      *) echo "unknown device: $DEVICE"; echo "available: ${deviceNames}"; exit 1 ;;
    esac

    ssh_() {
      ssh -o ConnectTimeout=5 "$HOST" "$@"
    }

    secrets='{}'
    for f in "''${SOPS_FILES[@]}"; do
      secrets=$(jq -s 'add' <(printf '%s' "$secrets") <(sops -d --output-type json "$f"))
    done

    # reuse the salt of the current hash so an unchanged password renders the same hash
    ROOT_PASSWORD_HASH=
    if [ -n "$PASSWORD_SECRET" ]; then
      password=$(printf '%s' "$secrets" | jq -er --arg k "$PASSWORD_SECRET" '.[$k]')
      current=$(ssh_ cat /etc/shadow | awk -F: '$1 == "root" { print $2 }')
      if [[ "$current" =~ ^\$([156])\$([^$]+)\$ ]]; then
        candidate=$(printf '%s\n' "$password" | openssl passwd "-''${BASH_REMATCH[1]}" -salt "''${BASH_REMATCH[2]}" -stdin)
        [ "$candidate" = "$current" ] && ROOT_PASSWORD_HASH=$current
      fi
      [ -n "$ROOT_PASSWORD_HASH" ] || ROOT_PASSWORD_HASH=$(printf '%s\n' "$password" | openssl passwd -6 -stdin)
    fi
    export ROOT_PASSWORD_HASH

    # render before connecting, so a sops or render failure leaves the device untouched
    program=$(openwrt-render "$CONFIG" <(printf '%s' "$secrets") "$MODE")

    if [ "$MODE" = plan ]; then
      echo "# plan for $DEVICE ($HOST)"
      printf '%s\n' "$program" | ssh_ ucode -
      exit 0
    fi

    echo "deploying $DEVICE to $HOST..."
    log=$(mktemp)
    trap 'rm -f "$log"' EXIT
    printf '%s\n' "$program" | ssh_ ucode - | tee "$log"
    dir=$(sed -n 's/^nix-uci-pending: //p' "$log")
    [ -n "$dir" ] || exit 0

    # fresh connections prove the device is still reachable after the reload;
    # the device restores the old state 120s after the apply unless confirmed
    deadline=$((SECONDS + 90))
    until ssh -o ConnectTimeout=5 -o BatchMode=yes "$HOST" test -e "$dir/reloaded" 2>/dev/null; do
      if [ "$SECONDS" -ge "$deadline" ]; then
        echo "error: $HOST unreachable after apply, it rolls back on its own" >&2
        exit 1
      fi
      sleep 2
    done
    sleep 5
    if ! ssh_ "mv $dir/pending $dir/confirmed"; then
      echo "error: confirm failed, $HOST rolled back or is unreachable; see $dir on the device" >&2
      exit 1
    fi
    ssh_ cat "$dir/apply.log"
    echo "confirmed."
  '';
}
