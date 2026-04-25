{
  flake.modules.nixos.ntfy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "ntfy";
      localHost = "${serviceName}.${config.domains.local}";
      publicHost = "${serviceName}.${config.domains.public}";
      listenAddress = "0.0.0.0";
      listenPort = 8091;
      listenUrl = "http://${listenAddress}:${toString listenPort}";

      topic = "systemd";
      cooldown = 300;
      excludeServices = [ "nixos-rebuild-switch-to-configuration" ];

      varsPath = config.clan.core.vars.generators.ntfy;

      notifyScript = pkgs.writeShellScript "systemd-notify" ''
        SERVICE="$1"
        TOKEN_FILE="${varsPath.files.token.path}"
        COOLDOWN_DIR="/run/systemd-notify-cooldown"
        COOLDOWN_SECS=${toString cooldown}

        if [ ! -f "$TOKEN_FILE" ]; then
          echo "ntfy token not found, skipping notification"
          exit 0
        fi

        mkdir -p "$COOLDOWN_DIR"
        COOLDOWN_FILE="$COOLDOWN_DIR/$SERVICE"
        if [ -f "$COOLDOWN_FILE" ]; then
          LAST=$(cat "$COOLDOWN_FILE")
          NOW=$(date +%s)
          if [ $((NOW - LAST)) -lt $COOLDOWN_SECS ]; then
            echo "rate limited: $SERVICE failed again within cooldown"
            exit 0
          fi
        fi
        date +%s > "$COOLDOWN_FILE"

        HOST=$(${pkgs.hostname}/bin/hostname)
        LOGS=$(${pkgs.systemd}/bin/journalctl -u "$SERVICE" -n 15 --no-pager -o cat 2>/dev/null | tail -10)

        ${pkgs.curl}/bin/curl -s \
          -X POST "${listenUrl}/${topic}" \
          -H "Authorization: Bearer $(cat $TOKEN_FILE)" \
          -H "Title: $SERVICE failed on $HOST" \
          -H "Priority: high" \
          -H "Tags: rotating_light" \
          -d "$LOGS"
      '';
    in
    {
      config = {
        clan.core.vars.generators.ntfy = {
          prompts.password.description = "ntfy admin password";
          prompts.password.type = "hidden";

          files."env".secret = true;
          files."token".secret = true;
          files."token-env".secret = true;

          runtimeInputs = [ pkgs.ntfy-sh ];

          script = ''
            PASSWORD=$(cat $prompts/password)
            HASH=$(printf '%s\n%s\n' "$PASSWORD" "$PASSWORD" | ntfy user hash)
            TOKEN=$(ntfy token generate)

            echo "$TOKEN" > $out/token
            echo "NTFY_TOKEN=$TOKEN" > $out/token-env
            echo "NTFY_AUTH_USERS=admin:$HASH:admin" > $out/env
            echo "NTFY_AUTH_TOKENS=admin:$TOKEN:clan-managed" >> $out/env
          '';
        };

        services.ntfy-sh = {
          enable = true;
          settings = {
            base-url = "https://${localHost}";
            listen-http = "${listenAddress}:${toString listenPort}";
            behind-proxy = true;
            auth-default-access = "deny-all";
            enable-login = true;
          };
        };

        services.homepage-dashboard.serviceGroups."Monitoring" =
          lib.mkIf config.services.homepage-dashboard.enable
            [
              {
                "ntfy" = {
                  href = "https://${publicHost}";
                  icon = "ntfy.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "ntfy";
            url = "https://${localHost}";
            group = "Monitoring";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "ntfy"; } ];
          }
        ];

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy ${listenUrl}
        '';

        systemd.services.ntfy-sh.serviceConfig.EnvironmentFile = varsPath.files."env".path;

        systemd.services."notify@" = {
          description = "send notification for failed service %i";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${notifyScript} %i";
          };
          unitConfig.OnFailure = lib.mkForce [ ];
        };

        systemd.packages = [
          (pkgs.writeTextFile {
            name = "systemd-notify-onfailure";
            destination = "/etc/systemd/system/service.d/10-onfailure.conf";
            text = ''
              [Unit]
              OnFailure=notify@%n.service
            '';
          })
        ]
        ++ map (
          name:
          pkgs.writeTextFile {
            name = "systemd-notify-exclude-${name}";
            destination = "/etc/systemd/system/${name}.service.d/99-no-notify.conf";
            text = ''
              [Unit]
              OnFailure=
            '';
          }
        ) excludeServices;
      };
    };
}
