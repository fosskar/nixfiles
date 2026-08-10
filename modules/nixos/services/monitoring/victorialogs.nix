{
  flake.modules.nixos.victoriaLogs =
    {
      config,
      lib,
      ...
    }:
    let
      listenPort = lib.last (lib.splitString ":" config.services.victorialogs.listenAddress);
    in
    {
      config = lib.mkIf config.services.victorialogs.enable {
        services.victorialogs = {
          listenAddress = lib.mkDefault "0.0.0.0:9428";
          extraOptions = [ "-enableTCP6" ];
        };

        # grafana datasource
        services.grafana.provision.datasources.settings.datasources = [
          {
            name = "VictoriaLogs";
            type = "victoriametrics-logs-datasource";
            access = "proxy";
            url = "http://127.0.0.1:${listenPort}";
          }
        ];
      };
    };
}
