{
  flake.modules.nixos.ollama =
    {
      flake-self,
      pkgs,
      ...
    }:
    let
      serviceName = "ollama";
      localHost = "${serviceName}.${flake-self.domains.local}";
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

      services.homepage-dashboard.services = [
        {
          "llm" = [
            {
              "Ollama" = {
                href = "https://${localHost}";
                icon = "ollama.png";
                siteMonitor = listenUrl;
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "Ollama";
          url = "${listenUrl}/api/tags";
          group = "AI";
          enabled = true;
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl} {
          header_up Host {upstream_hostport}
        }
      '';
    };
}
