{
  flake.modules.nixos.ollama =
    {
      nflib,
      flake-self,
      config,
      lib,
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

      services.homepage-dashboard.serviceGroups."llm" =
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
        (nflib.gatusEndpoint {
          name = "Ollama";
          url = "${listenUrl}/api/tags";
          group = "AI";
        })
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl} {
          header_up Host {upstream_hostport}
        }
      '';
    };
}
