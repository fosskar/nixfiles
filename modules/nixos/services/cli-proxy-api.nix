{
  flake.modules.nixos.cliProxyApi =
    { pkgs, ... }:
    let
      configFile = (pkgs.formats.yaml { }).generate "cli-proxy-api-config.yaml" {
        host = "127.0.0.1";
        port = 8317;
        auth-dir = "~/.cli-proxy-api";
        api-keys = [ "local" ];
        remote-management = {
          allow-remote = false;
          secret-key = "";
          disable-control-panel = true;
        };
        logging-to-file = false;
        usage-statistics-enabled = false;
      };
    in
    {
      environment.systemPackages = [ pkgs.cli-proxy-api ];

      home-manager.users.simon = {
        home.file.".cli-proxy-api/config.yaml".source = configFile;

        systemd.user.services.cli-proxy-api = {
          Unit = {
            Description = "CLIProxyAPI";
            After = [ "network-online.target" ];
          };

          Service = {
            ExecStart = "${pkgs.cli-proxy-api}/bin/cli-proxy-api -config %h/.cli-proxy-api/config.yaml";
            Restart = "on-failure";
            RestartSec = 5;
          };

          Install.WantedBy = [ "default.target" ];
        };
      };
    };
}
