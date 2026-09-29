_: {
  flake.modules.nixos.mcpGrafana =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
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
        # fencr runs it once per sandbox session, on a socket only its gateway reaches
        fencr.mcpGateway.servers.grafana = {
          command = [
            "${pkgs.writeShellScript "grafana-mcp-start" ''
              GRAFANA_PASSWORD="$(cat "$CREDENTIALS_DIRECTORY/grafana-password")"
              export GRAFANA_PASSWORD
              exec ${lib.getExe pkgs.mcp-grafana} \
                -t stdio \
                -enabled-tools ${lib.concatStringsSep "," enabledTools}
            ''}"
          ];
          # dashboards and datasources are provisioned from this repo
          hiddenTools = [
            "update_dashboard"
            "create_datasource"
            "update_datasource"
          ];
        };

        systemd.services."fencr-mcp-backend-grafana@" = {
          after = [ "grafana.service" ];
          wants = [ "grafana.service" ];
          environment = {
            GRAFANA_URL = grafanaUrl;
            GRAFANA_USERNAME = config.services.grafana.settings.security.admin_user;
          };
          serviceConfig = {
            LoadCredential = [
              "grafana-password:${grafanaVars.files."admin-password".path}"
            ];
            IPAddressAllow = [ "${config.services.grafana.settings.server.http_addr}/32" ];
            IPAddressDeny = "any";
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_UNIX"
            ];
          };
        };
      };
    };
}
