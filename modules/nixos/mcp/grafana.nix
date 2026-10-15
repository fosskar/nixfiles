_: {
  flake.modules.nixos.mcpGrafana =
    {
      config,
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      vars = config.clan.core.vars.generators.mcp-grafana;
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
      clan.core.vars.generators.mcp-grafana = {
        prompts.token = {
          description = "Grafana service account token for the MCP gateway";
          type = "hidden";
          persist = true;
        };
        files.token.secret = true;
        script = ''
          cp "$prompts/token" "$out/token"
        '';
      };

      # fencr runs it once per sandbox session, on a socket only its gateway reaches
      fencr.mcpGateway.servers.grafana = {
        command = [
          "${pkgs.writeShellScript "grafana-mcp-start" ''
            export GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE="$CREDENTIALS_DIRECTORY/token"
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
        environment.GRAFANA_URL = "https://grafana.${flake-self.domains.local}";
        serviceConfig = {
          LoadCredential = [ "token:${vars.files.token.path}" ];
          IPAddressAllow = [
            "127.0.0.53/32"
            "${flake-self.hosts.nixbox.lan}/32"
            "${builtins.head config.networking.nameservers}/32"
          ];
          IPAddressDeny = "any";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
        };
      };
    };
}
