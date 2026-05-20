{
  flake.modules.nixos.victoriaLogs =
    {
      config,
      lib,
      ...
    }:
    let
      listenAddress = "127.0.0.1";
      listenPort = 9428;
      grafanaListenAddress =
        if lib.hasPrefix "0.0.0.0:" config.services.victorialogs.listenAddress then
          "127.0.0.1:${toString listenPort}"
        else
          config.services.victorialogs.listenAddress;
    in
    {
      config = lib.mkIf config.services.victorialogs.enable {
        services.victorialogs = {
          listenAddress = lib.mkDefault "${listenAddress}:${toString listenPort}";
          extraOptions = [ "-enableTCP6" ];
        };

        # grafana datasource
        services.grafana.provision.datasources.settings.datasources = [
          {
            name = "VictoriaLogs";
            type = "victoriametrics-logs-datasource";
            access = "proxy";
            url = "http://${grafanaListenAddress}";
          }
        ];
      };
    };
}
