{
  # NVIDIA publishes the required vLLM release as a CUDA container before
  # nixpkgs can package it. This aspect runs that pinned image with Podman.
  flake.modules.nixos.vllm =
    {
      flake-self,
      config,
      lib,
      ...
    }:
    let
      localHost = "vllm.${flake-self.domains.local}";
      listenUrl = "http://${cfg.settings.host}:${toString cfg.settings.port}";
      cfg = config.services.vllm;
      commandLine = lib.cli.toCommandLineGNU { } cfg.settings;
    in
    {
      options.services.vllm = {

        image = lib.mkOption {
          type = lib.types.str;
          default = "docker.io/vllm/vllm-openai@sha256:0a51ea5b4ae2dc5d81890e5173f54203d2a3ae0cfffe51b8fd2afd4391bfd967";
          description = "OCI image for the vLLM server. The default digest is v0.27.1.";
        };

        autoStart = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Start vLLM during boot.";
        };

        model = lib.mkOption {
          type = lib.types.str;
          example = "nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4";
          description = ''
            Model served by `vllm serve`: a Hugging Face repository id or an
            absolute path to a local model directory. Hugging Face downloads
            land in {file}`/var/lib/vllm/huggingface`.
          '';
        };

        settings = lib.mkOption {
          type = lib.types.submodule {
            freeformType = lib.types.attrsOf (
              lib.types.oneOf [
                lib.types.bool
                lib.types.int
                lib.types.float
                lib.types.str
              ]
            );
            options = {
              host = lib.mkOption {
                type = lib.types.str;
                default = "127.0.0.1";
                example = "0.0.0.0";
                description = ''
                  IP address the server listens on. vLLM itself defaults to
                  all interfaces; this module defaults to loopback.
                '';
              };

              port = lib.mkOption {
                type = lib.types.port;
                default = 8000;
                description = ''
                  Port the server listens on.
                '';
              };
            };
          };
          default = { };
          example = {
            max-model-len = 32768;
            gpu-memory-utilization = 0.85;
            served-model-name = "qwen3.6-27b";
          };
          description = ''
            Command-line arguments for `vllm serve`, rendered as
            `--key value` pairs (`true` renders as a bare flag).

            See <https://docs.vllm.ai/en/stable/cli/serve.html>
            for the full list of options.
          '';
        };

        environment = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          example = {
            VLLM_ATTENTION_BACKEND = "FLASHINFER";
          };
          description = ''
            Extra environment variables for the server. vLLM reads most of
            its tuning knobs from `VLLM_*` variables, see
            <https://docs.vllm.ai/en/stable/configuration/env_vars.html>.
          '';
        };

        environmentFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          example = "/run/secrets/vllm";
          description = ''
            Environment file for secrets such as `HF_TOKEN` (gated models)
            or `VLLM_API_KEY` (client authentication).
          '';
        };

        openFirewall = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Open the listen port in the firewall.
          '';
        };
      };

      config = {
        services.vllm = {
          model = lib.mkDefault "nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4";
          settings = {
            served-model-name = lib.mkDefault "nemotron-3.5-lightning-30b-a3b";
            # Hermes context (98304) plus its hardcoded 65536 output cap for
            # custom providers: vllm hard-rejects prompt+max_tokens above this
            # with HTTP 400, and hermes retries such 400s with the same
            # max_tokens until "max compression attempts (3) reached"
            # (hermes-agent #49686, #51773). llama.cpp clamped instead.
            max-model-len = lib.mkDefault 163840;
            max-num-seqs = lib.mkDefault 2;
            gpu-memory-utilization = lib.mkDefault 0.95;
            kv-cache-dtype = lib.mkDefault "fp8";
            enable-prefix-caching = lib.mkDefault true;
            moe-backend = lib.mkDefault "marlin";
            mamba-backend = lib.mkDefault "flashinfer";
            mamba-cache-mode = lib.mkDefault "align";
            reasoning-parser = lib.mkDefault "nemotron_v3";
            default-chat-template-kwargs = lib.mkDefault (
              builtins.toJSON {
                enable_thinking = true;
                force_nonempty_content = true;
              }
            );
            tool-call-parser = lib.mkDefault "qwen3_coder";
            enable-auto-tool-choice = lib.mkDefault true;
          };
        };
        hardware.nvidia-container-toolkit.enable = true;
        virtualisation.docker.enable = true;

        systemd.tmpfiles.rules = [
          "d /var/lib/vllm/huggingface 0755 root root -"
          "d /var/cache/vllm 0755 root root -"
        ];

        virtualisation.oci-containers = {
          backend = "docker";
          containers.vllm = {
            inherit (cfg) autoStart;
            inherit (cfg) image;
            cmd = [ cfg.model ] ++ commandLine;
            environment = {
              HF_HOME = "/var/lib/vllm/huggingface";
              VLLM_CACHE_ROOT = "/var/cache/vllm";
              TRITON_CACHE_DIR = "/var/cache/vllm/triton";
              VLLM_NO_USAGE_STATS = "1";
              DO_NOT_TRACK = "1";
            }
            // cfg.environment;
            environmentFiles = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
            volumes = [
              "/var/lib/vllm/huggingface:/var/lib/vllm/huggingface"
              "/var/cache/vllm:/var/cache/vllm"
            ];
            extraOptions = [
              "--device=nvidia.com/gpu=all"
              "--ipc=host"
              "--network=host"
            ];
          };
        };

        systemd.services.docker-vllm.serviceConfig.RestartSec = 30;

        networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.settings.port;

        services.homepage-dashboard.services = [
          {
            "llm" = [
              {
                "vLLM" = {
                  href = "https://${localHost}";
                  icon = "sh-vllm";
                  siteMonitor = "${listenUrl}/health";
                };
              }
            ];
          }
        ];

        services.gatus.settings.endpoints = [
          {
            name = "vLLM";
            url = "https://${localHost}/health";
            enabled = cfg.autoStart;
            alerts = [ { type = "email"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy ${listenUrl}
        '';
      };
    };
}
