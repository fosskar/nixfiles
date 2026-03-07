{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.ntfy;
  acmeDomain = config.nixfiles.acme.domain;
  serviceDomain = "ntfy.${acmeDomain}";
  bindAddress = "127.0.0.1";
  port = 8091;
  internalUrl = "http://${bindAddress}:${toString port}";

  varsPath = config.clan.core.vars.generators.ntfy;

  notifyScript = pkgs.writeShellScript "systemd-notify" ''
    SERVICE="$1"
    TOKEN_FILE="${varsPath.files.token.path}"
    COOLDOWN_DIR="/run/systemd-notify-cooldown"
    COOLDOWN_SECS=${toString cfg.systemd-notify.cooldown}

    # skip if token doesn't exist yet
    if [ ! -f "$TOKEN_FILE" ]; then
      echo "ntfy token not found, skipping notification"
      exit 0
    fi

    # rate limit: skip if notified recently
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
      -X POST "http://${bindAddress}:${toString port}/${cfg.systemd-notify.topic}" \
      -H "Authorization: Bearer $(cat $TOKEN_FILE)" \
      -H "Title: $SERVICE failed on $HOST" \
      -H "Priority: high" \
      -H "Tags: rotating_light" \
      -d "$LOGS"
  '';
in
{
  # --- options ---

  options.nixfiles.ntfy.systemd-notify = {
    topic = lib.mkOption {
      type = lib.types.str;
      default = "systemd";
      description = "ntfy topic for systemd failure notifications";
    };

    cooldown = lib.mkOption {
      type = lib.types.int;
      default = 300;
      description = "cooldown in seconds between notifications for the same service";
    };

    excludeServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "nixos-rebuild-switch-to-configuration" ];
      description = "services to exclude from failure notifications";
    };
  };

  # --- secrets ---

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

    # --- service ---

    services.ntfy-sh = {
      enable = true;
      settings = {
        base-url = "https://${serviceDomain}";
        listen-http = "${bindAddress}:${toString port}";
        behind-proxy = true;
        auth-default-access = "deny-all";
        enable-login = true;
      };
    };

    # --- homepage ---

    nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
      {
        name = "ntfy";
        category = "Monitoring";
        icon = "ntfy.svg";
        href = "https://${serviceDomain}";
        siteMonitor = internalUrl;
      }
    ];

    # --- gatus ---

    nixfiles.gatus.endpoints = lib.mkIf config.nixfiles.gatus.enable [
      {
        name = "ntfy";
        url = "https://${serviceDomain}";
        group = "Monitoring";
      }
    ];

    # --- nginx ---

    nixfiles.nginx.vhosts.ntfy = {
      inherit port;
    };

    # --- systemd ---

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
    ) cfg.systemd-notify.excludeServices;
  };
}
