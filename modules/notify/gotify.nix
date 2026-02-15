{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.notify;
  tokenDir = "/run/gotify-tokens";
  tokenFile = name: "${tokenDir}/${name}";

  # include built-in app plus user-defined applications
  allApps = {
    systemd-notify = "systemd failure notifications";
  }
  // cfg.gotify.applications;

  notifyScript = pkgs.writeShellScript "systemd-notify" ''
    SERVICE="$1"
    TOKEN_FILE="${tokenFile "systemd-notify"}"
    COOLDOWN_DIR="/run/systemd-notify-cooldown"
    COOLDOWN_SECS=300  # 5 min cooldown per service

    # skip if token doesn't exist yet
    if [ ! -f "$TOKEN_FILE" ]; then
      echo "gotify app token not found, skipping notification"
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
    # get last 10 log lines, filter to errors/relevant info
    LOGS=$(${pkgs.systemd}/bin/journalctl -u "$SERVICE" -n 15 --no-pager -o cat 2>/dev/null | tail -10)

    JSON=$(${pkgs.jq}/bin/jq -n \
      --arg title "🔴 $SERVICE failed" \
      --arg host "$HOST" \
      --arg logs "$LOGS" \
      '{title: $title, message: "Host: \($host)\n\n\($logs)", priority: 8}')

    ${pkgs.curl}/bin/curl -s \
      -X POST "http://127.0.0.1:${toString cfg.gotify.port}/message?token=$(cat $TOKEN_FILE)" \
      -H "Content-Type: application/json" \
      -d "$JSON"
  '';

  bootstrapScript = pkgs.writeShellScript "gotify-bootstrap" ''
    set -euo pipefail

    TOKEN_DIR="${tokenDir}"
    PORT="${toString cfg.gotify.port}"
    PASSWORD_FILE="${config.clan.core.vars.generators.gotify.files.password.path}"

    mkdir -p "$TOKEN_DIR"
    PASSWORD=$(cat "$PASSWORD_FILE")

    # wait for gotify to be ready
    for i in $(seq 1 30); do
      if ${pkgs.curl}/bin/curl -s "http://127.0.0.1:$PORT/health" > /dev/null 2>&1; then
        break
      fi
      echo "waiting for gotify..."
      sleep 1
    done

    # create applications
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: description: ''
        # check if app exists in gotify
        EXISTING=$(${pkgs.curl}/bin/curl -s -u "admin:$PASSWORD" \
          "http://127.0.0.1:$PORT/application" | \
          ${pkgs.jq}/bin/jq -r '.[] | select(.name == "${name}") | .token' | head -1)

        if [ -n "$EXISTING" ]; then
          echo "$EXISTING" > "$TOKEN_DIR/${name}"
          chmod 644 "$TOKEN_DIR/${name}"
          echo "${name}: synced token from gotify"
        else
          RESPONSE=$(${pkgs.curl}/bin/curl -s -u "admin:$PASSWORD" \
            -X POST "http://127.0.0.1:$PORT/application" \
            -F "name=${name}" \
            -F "description=${description}")

          TOKEN=$(echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '.token')

          if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
            echo "${name}: failed to create - $RESPONSE"
          else
            echo "$TOKEN" > "$TOKEN_DIR/${name}"
            chmod 644 "$TOKEN_DIR/${name}"
            echo "${name}: created"
          fi
        fi
      '') allApps
    )}
  '';
in
{
  options.nixfiles.notify = {
    excludeServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "nixos-rebuild-switch-to-configuration" ];
      description = "services to exclude from failure notifications";
    };

    gotify = {
      port = lib.mkOption {
        type = lib.types.port;
        default = 8070;
        description = "gotify server port";
      };

      applications = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "additional gotify applications to create (name = description)";
        example = {
          grafana = "grafana alerts";
          backup = "backup notifications";
        };
      };

      tokenFile = lib.mkOption {
        type = lib.types.attrsOf lib.types.path;
        readOnly = true;
        default = lib.mapAttrs (name: _: tokenFile name) allApps;
        description = "paths to token files for each application";
      };
    };
  };

  config = {
    clan.core.vars.generators.gotify = {
      prompts.password.description = "gotify admin password";
      prompts.password.type = "hidden";
      prompts.password.persist = false;

      files.env.secret = true;
      files.password.secret = true;

      script = ''
        cp $prompts/password $out/password
        echo "GOTIFY_DEFAULTUSER_PASS=$(cat $prompts/password)" > $out/env
      '';
    };

    services.gotify = {
      enable = true;
      environment = {
        GOTIFY_SERVER_PORT = toString cfg.gotify.port;
        GOTIFY_DEFAULTUSER_NAME = "admin";
      };
      environmentFiles = [ config.clan.core.vars.generators.gotify.files.env.path ];
    };

    # bootstrap: create gotify apps and save tokens
    systemd.services.gotify-bootstrap = {
      description = "bootstrap gotify applications";
      after = [ "gotify-server.service" ];
      requires = [ "gotify-server.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = bootstrapScript;
      };
    };

    # notification service template
    systemd.services."notify@" = {
      description = "send notification for failed service %i";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${notifyScript} %i";
      };
      unitConfig.OnFailure = lib.mkForce [ ];
    };

    # global drop-in to hook OnFailure into all services
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
    # drop-ins to exclude specific services
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
    ) cfg.excludeServices;
  };
}
