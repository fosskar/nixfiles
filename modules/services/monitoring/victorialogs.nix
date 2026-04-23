{
  flake.modules.nixos.victoriaLogs =
    {
      config,
      lib,
      ...
    }:
    let
      port = 9428;
    in
    {
      config = lib.mkIf config.services.victorialogs.enable {
        services.victorialogs = {
          listenAddress = lib.mkDefault "127.0.0.1:${toString port}";
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
