_: {
  flake.modules.nixos.mcpGrafana =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      listenPort = 8766;
      vars = config.clan.core.vars.generators.grafana-mcp;
      grafanaVars = config.clan.core.vars.generators.grafana;
      grafanaUrl = "http://${config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
      # cloud-only categories (incident, oncall, sift, asserts, pyroscope,
      # agento11y, assistant) and the image renderer are not present here.
      # loki tools drive victorialogs through tools/loki_backend_victorialogs.go
      enabledTools = [
        "search"
        "datasource"
        "prometheus"
        "loki"
        "alerting"
        "dashboard"
        "folder"
        "navigation"
        "annotations"
      ];
    in
    {
      config = lib.mkIf config.services.grafana.enable {
        clan.core.vars.generators.grafana-mcp = {
          files.token.secret = true;
          runtimeInputs = [ pkgs.openssl ];
          script = ''
            openssl rand -hex 32 > "$out/token"
          '';
        };

        fencr.mcpGateway.servers.grafana = {
          service = "grafana-mcp.service";
          url = "http://127.0.0.1:${toString listenPort}/mcp";
          tokenFile = vars.files.token.path;
          # dashboards and datasources are provisioned from this repo
          hiddenTools = [
            "update_dashboard"
            "create_datasource"
            "update_datasource"
          ];
          # alerting_manage_* also cover list/get; the gateway gates by tool name
          approvalTools = [
            "create_folder"
            "alerting_manage_rules"
            "alerting_manage_routing"
            "alerting_manage_silences"
            "create_annotation"
            "update_annotation"
          ];
        };

        systemd.services.grafana-mcp = {
          description = "Grafana MCP server";
          wantedBy = [ "multi-user.target" ];
          after = [ "grafana.service" ];
          wants = [ "grafana.service" ];
          environment = {
            GRAFANA_URL = grafanaUrl;
            GRAFANA_USERNAME = config.services.grafana.settings.security.admin_user;
          };
          serviceConfig = {
            DynamicUser = true;
            LoadCredential = [
              "grafana-password:${grafanaVars.files."admin-password".path}"
              "token:${vars.files.token.path}"
            ];
            ExecStart = pkgs.writeShellScript "grafana-mcp-start" ''
              GRAFANA_PASSWORD="$(cat "$CREDENTIALS_DIRECTORY/grafana-password")"
              MCP_GRAFANA_SERVER_TOKEN="$(cat "$CREDENTIALS_DIRECTORY/token")"
              export GRAFANA_PASSWORD MCP_GRAFANA_SERVER_TOKEN
              exec ${lib.getExe pkgs.mcp-grafana} \
                -t streamable-http \
                -address 127.0.0.1:${toString listenPort} \
                -enabled-tools ${lib.concatStringsSep "," enabledTools}
            '';
            Restart = "on-failure";
            RestartSec = 5;

            CapabilityBoundingSet = "";
            IPAddressAllow = [
              "127.0.0.0/8"
              "::1/128"
            ];
            IPAddressDeny = "any";
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            NoNewPrivileges = true;
            PrivateDevices = true;
            PrivateTmp = true;
            ProtectClock = true;
            ProtectControlGroups = true;
            ProtectHome = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectProc = "invisible";
            ProtectSystem = "strict";
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
              "AF_UNIX"
            ];
            RestrictNamespaces = true;
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            SystemCallArchitectures = "native";
            SystemCallFilter = [
              "@system-service"
              "~@privileged"
              "~@resources"
            ];
            UMask = "0077";
          };
        };
      };
    };
}
