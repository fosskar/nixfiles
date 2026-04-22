{
  flake.modules.nixos.victoriaLogs =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.nixfiles.monitoring.victorialogs;
      inherit (cfg) port;
    in
    {
      # --- options ---

      options.nixfiles.monitoring.victorialogs = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "victorialogs log aggregation";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 9428;
          description = "victorialogs listen port";
        };

      };

      config = lib.mkIf cfg.enable {
        # --- service ---

        services.victorialogs = {
          enable = true;
          listenAddress = "127.0.0.1:${toString port}";
          extraOptions = [ "-enableTCP6" ];
        };

        # grafana datasource
        services.grafana.provision.datasources.settings.datasources = [
          {
            name = "VictoriaLogs";
            type = "victoriametrics-logs-datasource";
            access = "proxy";
            url = "http://${config.services.victorialogs.listenAddress}";
          }
        ];
      };
    };
}
