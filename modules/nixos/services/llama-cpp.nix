{
  flake.modules.nixos.llamaCpp =
    {
      nflib,
      flake-self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "llama-cpp";
      localHost = "${serviceName}.${flake-self.domains.local}";
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
          models-max = 1;
          models-preset = (pkgs.formats.ini { }).generate "llama-cpp-models-preset.ini" {
            "*" = {
              ctx-size = 32768;
              flash-attn = "on";
              cache-type-k = "q8_0";
              cache-type-v = "q8_0";
            };
            gemma4-e4b = {
              hf-repo = "unsloth/gemma-4-E4B-it-GGUF";
              hf-file = "gemma-4-E4B-it-Q4_K_M.gguf";
              alias = "gemma4-e4b";
              ctx-size = 131072;
              temp = 1.0;
              top-p = 0.95;
              top-k = 64;
              reasoning = "off";
            };
            gemma4-12b = {
              hf-repo = "unsloth/gemma-4-12b-it-GGUF";
              hf-file = "gemma-4-12b-it-Q4_K_M.gguf";
              alias = "gemma4-12b";
              temp = 1.0;
              top-p = 0.95;
              top-k = 64;
              reasoning = "off";
            };
            qwen3_6-27b = {
              hf-repo = "unsloth/Qwen3.6-27B-GGUF";
              hf-file = "Qwen3.6-27B-UD-Q4_K_XL.gguf";
              alias = "qwen3.6-27b";
              temp = 0.7;
              top-p = 0.8;
              top-k = 20;
              presence-penalty = 1.5;
              min-p = 0.00;
              reasoning = "off";
            };
            qwen3_6-27b-mtp = {
              hf-repo = "unsloth/Qwen3.6-27B-MTP-GGUF";
              hf-file = "Qwen3.6-27B-UD-Q4_K_XL.gguf";
              alias = "qwen3.6-27b-mtp";
              temp = 0.7;
              top-p = 0.8;
              top-k = 20;
              presence-penalty = 1.5;
              min-p = 0.00;
              reasoning = "off";
              spec-type = "draft-mtp";
              cache-type-k-draft = "q4_0";
              cache-type-v-draft = "q4_0";
            };
            qwopus3_6-27b-v2-mtp = {
              hf-repo = "Jackrong/Qwopus3.6-27B-v2-MTP-GGUF";
              hf-file = "Qwopus3.6-27B-v2-MTP-Q4_K_M.gguf";
              alias = "qwopus3.6-27b-v2-mtp";
              parallel = 1;
              temp = 1.0;
              top-p = 0.95;
              top-k = 20;
              reasoning = "on";
              spec-type = "draft-mtp";
              cache-type-k-draft = "q4_0";
              cache-type-v-draft = "q4_0";
            };
            qwen3_6-35b-a3b = {
              hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF";
              hf-file = "Qwen3.6-35B-A3B-UD-Q4_K_M.gguf";
              alias = "qwen3.6-35b-a3b";
              temp = 0.7;
              top-p = 0.8;
              top-k = 20;
              presence-penalty = 1.5;
              min-p = 0.00;
              reasoning = "off";
            };
          };
        };
      };

      services.homepage-dashboard.serviceGroups."llm" =
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
