{
  flake.modules.nixos.systemdEmailAlerts =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      from = "noreply@nx3.eu";
      to = "${config.networking.hostName}@nx3.eu";
      cooldown = 300;
      alertDelay = 300;
      excludeServices = [ "nixos-rebuild-switch-to-configuration" ];
      extraAlertedServices = config.services.systemdEmailAlerts.extraServices;

      enabledNixosServiceNames = lib.attrNames (
        lib.filterAttrs (_: value: value) (
          lib.mapAttrs (
            name: value:
            builtins.hasAttr "enable" options.services."${name}"
            && builtins.hasAttr "default" options.services."${name}".enable
            && options.services."${name}".enable.default != value.enable
            && value.enable
          ) config.services
        )
      );

      matchesNixosServiceName =
        unitName: serviceName:
        unitName == serviceName
        || lib.hasPrefix "${serviceName}-" unitName
        || lib.hasSuffix "-${serviceName}" unitName
        || lib.hasInfix "-${serviceName}-" unitName;

      alertedSystemdServices = lib.subtractLists excludeServices (
        lib.unique (
          extraAlertedServices
          ++ lib.filter (unitName: lib.any (matchesNixosServiceName unitName) enabledNixosServiceNames) (
            lib.attrNames config.systemd.services
          )
        )
      );

      notifyScript = pkgs.writeShellScript "systemd-email-alert" ''
        SERVICE="$1"
        COOLDOWN_DIR="/run/systemd-email-alert-cooldown"
        COOLDOWN_SECS=${toString cooldown}
        ALERT_DELAY_SECS=${toString alertDelay}

        ${pkgs.coreutils}/bin/sleep "$ALERT_DELAY_SECS"
        if ! ${pkgs.systemd}/bin/systemctl is-failed --quiet "$SERVICE"; then
          echo "service recovered before alert delay: $SERVICE"
          exit 0
        fi

        ${pkgs.coreutils}/bin/mkdir -p "$COOLDOWN_DIR"
        COOLDOWN_FILE="$COOLDOWN_DIR/$SERVICE"
        if [ -f "$COOLDOWN_FILE" ]; then
          LAST=$(${pkgs.coreutils}/bin/cat "$COOLDOWN_FILE")
          NOW=$(${pkgs.coreutils}/bin/date +%s)
          if [ $((NOW - LAST)) -lt $COOLDOWN_SECS ]; then
            echo "rate limited: $SERVICE failed again within cooldown"
            exit 0
          fi
        fi
        ${pkgs.coreutils}/bin/date +%s > "$COOLDOWN_FILE"

        HOST=$(${pkgs.hostname}/bin/hostname)
        LOGS=$(${pkgs.systemd}/bin/journalctl -u "$SERVICE" -n 15 --no-pager -o cat 2>/dev/null | ${pkgs.coreutils}/bin/tail -10)
        SUBJECT="$SERVICE failed on $HOST"

        {
          printf 'From: System Alerts <%s>\n' '${from}'
          printf 'To: %s\n' '${to}'
          printf 'Subject: %s\n' "$SUBJECT"
          printf '\n'
          printf '%s\n\n' "$SUBJECT"
          printf '%s\n' "$LOGS"
        } | /run/wrappers/bin/sendmail -t
      '';
    in
    {
      options.services.systemdEmailAlerts.extraServices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          additional systemd service unit names (without `.service`) to alert on.
          use for services whose nixos option has `enable.default = true` and are
          therefore not detected by the opted-in heuristic.
        '';
      };

      config = lib.mkIf config.programs.msmtp.enable {
        systemd.services."notify-email@" = {
          description = "send email for failed service %i";
          serviceConfig = {
            Type = "oneshot";
            TimeoutStartSec = "6min";
            ExecStart = "${notifyScript} %i";
          };
          unitConfig.OnFailure = lib.mkForce [ ];
        };

        systemd.packages = map (
          name:
          pkgs.writeTextFile {
            name = "systemd-email-alert-${name}";
            destination = "/etc/systemd/system/${name}.service.d/10-email-alert.conf";
            text = ''
              [Unit]
              OnFailure=notify-email@%n.service
            '';
          }
        ) alertedSystemdServices;
      };
    };
}
