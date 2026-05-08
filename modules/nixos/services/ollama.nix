{
  flake.modules.nixos.ollama =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "ollama";
      localHost = "${serviceName}.${config.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 11434;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      services.ollama = {
        enable = true;
        package = pkgs.ollama-cuda;
        host = listenAddress;
        port = listenPort;
        openFirewall = false;
        environmentVariables.OLLAMA_ORIGINS = "http://${localHost},https://${localHost},app://*,zed://*";

        loadModels = [
          # llm

          # vision
          "minicpm-v:8b"
        ];
      };

      services.homepage-dashboard.serviceGroups."AI" =
        lib.mkIf config.services.homepage-dashboard.enable
          [
            {
              "Ollama" = {
                href = "https://${localHost}";
                icon = "ollama.png";
                siteMonitor = listenUrl;
              };
            }
          ];

      services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
        {
          name = "Ollama";
          url = "${listenUrl}/api/tags";
          group = "AI";
          enabled = true;
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [ { type = "ntfy"; } ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl} {
          header_up Host {upstream_hostport}
        }
      '';
    };
}
