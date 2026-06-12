{
  flake.modules.nixos.llamaCpp =
    {
      nflib,
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
        openFirewall = false;
        settings = {
          host = listenAddress;
          port = listenPort;
          n-gpu-layers = 999;
          models-preset = (pkgs.formats.ini { }).generate "llama-cpp-models-preset.ini" {
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
            qwen3_6-27b = {
              hf-repo = "unsloth/Qwen3.6-27B-GGUF";
              hf-file = "Qwen3.6-27B-UD-Q4_K_XL.gguf";
              alias = "qwen3.6-27b";
              jinja = "on";
              ctx-size = 32768;
              parallel = 1;
              temp = 0.7;
              top-p = 0.8;
              top-k = 20;
              presence-penalty = 1.5;
              min-p = 0.00;
              reasoning = "off";
            };
            qwen3_6-35b-a3b = {
              hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF";
              hf-file = "Qwen3.6-35B-A3B-UD-Q4_K_M.gguf";
              alias = "qwen3.6-35b-a3b";
              jinja = "on";
              ctx-size = 32768;
              parallel = 1;
              temp = 0.7;
              top-p = 0.8;
              top-k = 20;
              presence-penalty = 1.5;
              min-p = 0.00;
              reasoning = "off";
              flash-attn = "on";
              cache-type-k = "q4_0";
              cache-type-v = "q4_0";
            };
          };
        };
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
        (nflib.gatusEndpoint {
          name = "llama.cpp";
          url = "${listenUrl}/health";
          group = "AI";
        })
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';
    };
}
