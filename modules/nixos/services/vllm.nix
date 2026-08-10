{
  # nixpkgs ships the vllm package but no service module; this aspect fills
  # that gap in the style of the upstream llama-cpp module. import it, then
  # set services.vllm.enable and services.vllm.model.
  flake.modules.nixos.vllm =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.vllm;
    in
    {
      options.services.vllm = {
        enable = lib.mkEnableOption "vLLM OpenAI-compatible inference server";

        package = lib.mkPackageOption pkgs "vllm" { };

        model = lib.mkOption {
          type = lib.types.str;
          example = "nvidia/Qwen3.6-27B-NVFP4";
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

      config = lib.mkMerge [
        # repo defaults: unsloth NVFP4 W4A4 quant with built-in MTP tensors on
        # blackwell, per https://unsloth.ai/docs/models/qwen3.6#nvfp4 (leave
        # gemm/moe backend auto-selected; forcing marlin is 2.5x slower).
        # unsloth states vllm >= 0.25.0 for these quants; nixpkgs is at 0.24.0
        # until https://github.com/NixOS/nixpkgs/pull/549327 lands.
        {
          services.vllm = {
            # cache.nixos-cuda.org serves pkgsCuda (cudaSupport with default
            # capabilities); narrowing to the host cudaCapabilities misses the
            # cache, so re-import the host nixpkgs with a clean cuda config
            package =
              lib.mkDefault
                (import pkgs.path {
                  inherit (pkgs.stdenv.hostPlatform) system;
                  config = {
                    allowUnfree = true;
                    cudaSupport = true;
                  };
                }).vllm;
            model = lib.mkDefault "unsloth/Qwen3.6-27B-NVFP4";
            settings = {
              served-model-name = lib.mkDefault "qwen3.6-27b";
              # full 262144 context does not fit next to 27B weights in 24GB vram
              max-model-len = lib.mkDefault 32768;
              speculative-config = lib.mkDefault (
                builtins.toJSON {
                  method = "mtp";
                  num_speculative_tokens = 2;
                }
              );
            };
          };
        }
        (lib.mkIf cfg.enable {
          systemd.services.vllm = {
            description = "vLLM OpenAI-compatible inference server";
            wants = [ "network-online.target" ];
            after = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];

            environment = {
              HOME = "/var/lib/vllm";
              # model weights are expensive to fetch; keep them in state, not cache
              HF_HOME = "/var/lib/vllm/huggingface";
              VLLM_CACHE_ROOT = "/var/cache/vllm";
              TRITON_CACHE_DIR = "/var/cache/vllm/triton";
              VLLM_NO_USAGE_STATS = "1";
              DO_NOT_TRACK = "1";
            }
            // cfg.environment;

            serviceConfig = {
              ExecStart = "${lib.getExe' cfg.package "vllm"} serve ${lib.escapeShellArg cfg.model} ${
                lib.cli.toCommandLineShellGNU { } cfg.settings
              }";
              EnvironmentFile = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
              Restart = "on-failure";
              RestartSec = 30;
              # model download, weight loading, and torch.compile warmup
              TimeoutStartSec = "infinity";

              DynamicUser = true;
              StateDirectory = "vllm";
              CacheDirectory = "vllm";
              WorkingDirectory = "/var/lib/vllm";

              AmbientCapabilities = [ "" ];
              CapabilityBoundingSet = [ "" ];
              LockPersonality = true;
              # torch/triton JIT need writable executable mappings
              MemoryDenyWriteExecute = false;
              NoNewPrivileges = true;
              PrivateDevices = false; # GPU access
              PrivateMounts = true;
              PrivateTmp = true;
              PrivateUsers = true;
              ProcSubset = "pid";
              ProtectClock = true;
              ProtectControlGroups = true;
              ProtectHome = true;
              ProtectHostname = true;
              ProtectKernelLogs = true;
              ProtectKernelModules = true;
              ProtectKernelTunables = true;
              ProtectProc = "invisible";
              ProtectSystem = "strict";
              RemoveIPC = true;
              RestrictAddressFamilies = [
                "AF_INET"
                "AF_INET6"
                "AF_UNIX"
                "AF_NETLINK" # nccl interface discovery
              ];
              RestrictNamespaces = true;
              RestrictRealtime = true;
              RestrictSUIDSGID = true;
              SystemCallArchitectures = "native";
              SystemCallErrorNumber = "EPERM";
              SystemCallFilter = [
                "@system-service"
                "~@privileged"
              ];
            };
          };

          networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.settings.port;
        })
      ];
    };
}
