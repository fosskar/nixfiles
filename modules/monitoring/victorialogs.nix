{
  config,
  lib,
  ...
}:
let
  cfg = config.nixfiles.monitoring.victorialogs;
in
{
  options.nixfiles.monitoring.victorialogs = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "victorialogs log aggregation";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1:9428";
      description = "listen address for VictoriaLogs";
    };
  };

  config = lib.mkIf cfg.enable {
    services.victorialogs = {
      enable = true;
      inherit (cfg) listenAddress;
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
}
