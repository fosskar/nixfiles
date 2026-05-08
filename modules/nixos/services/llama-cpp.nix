{
  flake.modules.nixos.llamaCpp =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "llama-cpp";
      localHost = "${serviceName}.${config.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 18080;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      services.llama-cpp = {
        enable = true;
        package = pkgs.llama-cpp.override { cudaSupport = true; };
        host = listenAddress;
        port = listenPort;
        openFirewall = false;
        modelsPreset = {
          gemma4-e4b = {
            hf-repo = "unsloth/gemma-4-E4B-it-GGUF";
            hf-file = "gemma-4-E4B-it-Q4_K_M.gguf";
            alias = "gemma4-e4b";
            jinja = "on";
            ctx-size = 131072;
            parallel = 2;
          };
          granite = {
            hf-repo = "ibm-granite/granite-4.1-8b-GGUF";
            hf-file = "granite-4.1-8b-Q4_K_M.gguf";
            alias = "granite4.1-8b";
            jinja = "on";
            ctx-size = 65536;
            parallel = 1;
          };
        };
        extraFlags = [
          "--n-gpu-layers"
          "999"
        ];
      };

      services.homepage-dashboard.serviceGroups."AI" =
        lib.mkIf config.services.homepage-dashboard.enable
          [
            {
              "llama.cpp" = {
                href = "https://${localHost}";
                icon = "llama-cpp.png";
                siteMonitor = "${listenUrl}/health";
              };
            }
          ];

      services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
        {
          name = "llama.cpp";
          url = "${listenUrl}/health";
          group = "AI";
          enabled = true;
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [ { type = "ntfy"; } ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';
    };
}
