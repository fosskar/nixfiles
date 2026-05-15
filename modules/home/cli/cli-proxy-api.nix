{
  flake.modules.homeManager.cliProxyApi =
    { inputs, pkgs, ... }:
    let
      configFile = (pkgs.formats.yaml { }).generate "cli-proxy-api-config.yaml" {
        host = "127.0.0.1";
        port = 8317;
        auth-dir = "~/.cli-proxy-api";
        api-keys = [ ];
        remote-management.disable-control-panel = true;
      };
    in
    {
      home.packages = [
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.cli-proxy-api
      ];

      home.file.".cli-proxy-api/config.yaml".source = configFile;

      systemd.user.services.cli-proxy-api = {
        Unit = {
          Description = "CLIProxyAPI";
          After = [ "network-online.target" ];
        };

        Service = {
          ExecStart = "${
            inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.cli-proxy-api
          }/bin/cli-proxy-api -config %h/.cli-proxy-api/config.yaml";
          Restart = "on-failure";
          RestartSec = 5;

          CapabilityBoundingSet = "";
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
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
        };

        Install.WantedBy = [ "default.target" ];
      };
    };
}
