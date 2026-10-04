let
  # router and rpc server must run the same build: the rpc protocol is versioned
  pinned =
    pkgs: package:
    package.overrideAttrs {
      version = "11371";
      src = pkgs.fetchFromGitHub {
        owner = "ggml-org";
        repo = "llama.cpp";
        rev = "99b95488cac0f00ce3f05af113a8c1e287753f87";
        hash = "sha256-DbFgp028eMgQLNfKu2p4hFRWK5bmJPUNPYIAWvI120U=";
      };
      npmDepsHash = "sha256-a17M+L3nLdRnN6WMB6imPFmwqG2g8uv+gwN0XTAUrf8=";
      # kolibri1 is not upstream yet (ggml-org/llama.cpp#29922); the patch
      # only loads ggufs converted by that repo
      patches = [
        (pkgs.fetchurl {
          url = "https://huggingface.co/Hob-forge/Kolibri-1-GGUF/resolve/a542f8dfe9083e8924d381a1645347bf10b67632/kolibri1-llama.cpp.patch";
          hash = "sha256-4NF8JqA3hKgmfLFqcofotOfXmZebWEM0dwv362IMZqo=";
        })
      ];
    };
  rpcPort = 50052;
in
{
  flake.modules.nixos.llamaCpp =
    {
      flake-self,
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
      startupModelAlias = "kolibri-1";
      modelsDir = "/var/lib/llama-cpp-models";
      # pinned to immutable HF revisions: resolve/main lets upstream re-upload
      # weights in place, and llama.cpp's etag check then silently re-downloads
      # the swapped file on the next model load
      models = {
        "unsloth/Qwen3.8-27B-GGUF" = {
          rev = "4ca720788d1e01f1bff70c033e0d0028fd02e502";
          files = {
            "Qwen3.8-27B-UD-Q4_K_M.gguf" = "322e194ff79741c7baa497c240f677f54b201b0efab44ca8e50f122b39123482";
            "MTP/mtp-Qwen3.8-27B-Q4_0.gguf" =
              "50d9ce5a6da381bbcfb31061cf73df94a90e6faf8efeddee379a9cb8f1501c6e";
            "mmproj-F16.gguf" = "cbb841a9ee0636b2ec172f5bb8df2ea8dfeb01e90fe7c6126581d662a0b4e43e";
          };
        };
        "unsloth/Qwen3.6-35B-A3B-MTP-GGUF" = {
          rev = "5bc3e238d916f48a861bac2f8a1990a0e9b7e98d";
          files = {
            "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf" =
              "55983c5a75a1ab969824077b3bb3de4146e82a9234072b48ad4e8f92ad3fe9f1";
            "Qwen3.6-35B-A3B-UD-Q6_K.gguf" = "49935b04ad883c2f3d4da61f65b609d447dad67d0b08453b90abb09a1bb35464";
            "mmproj-F16.gguf" = "71f3cbc1f7cc0f30d09d41cfa924c0060827ebc33bf15ace7e86661e856f0160";
          };
        };
        "Hob-forge/Kolibri-1-GGUF" = {
          rev = "a542f8dfe9083e8924d381a1645347bf10b67632";
          files = {
            "Kolibri-1-Q4_K_M.gguf" = "c2ac1301424441ef210b6de50ce25e8ccf69f86494df53d6ba52ed558456062e";
          };
        };
        "ggml-org/Laya-GGUF" = {
          rev = "da4b4753d62197659d8c90103cd4c43bef9afea6";
          files = {
            "Laya-Q8_0.gguf" = "c06528c5746d3bb8baa72a27938be95abbfd0b226f8471e8a9e365ed0bb066d2";
          };
        };
      };
      modelPath = repo: file: "${modelsDir}/${repo}/${file}";
      manifest = pkgs.writeText "llama-cpp-models.manifest" (
        lib.concatMapStrings (
          repo:
          lib.concatMapStrings (
            file: "${repo} ${file} ${models.${repo}.rev} ${models.${repo}.files.${file}}\n"
          ) (lib.attrNames models.${repo}.files)
        ) (lib.attrNames models)
      );
      keepList = pkgs.writeText "llama-cpp-models.keep" (
        lib.concatMapStrings (
          repo: lib.concatMapStrings (file: "${repo}/${file}\n") (lib.attrNames models.${repo}.files)
        ) (lib.attrNames models)
      );
    in
    {
      services.llama-cpp = {
        enable = true;
        package = pinned pkgs (
          pkgs.llama-cpp.override {
            cudaSupport = true;
            rpcSupport = true;
          }
        );
        openFirewall = false;
        settings = {
          host = listenAddress;
          port = listenPort;
          metrics = true;
          models-max = 2;
          models-preset = (pkgs.formats.ini { }).generate "llama-cpp-models-preset.ini" {
            "*" = {
              ctx-size = 32768;
              flash-attn = "on";
              cache-type-k = "q8_0";
              cache-type-v = "q8_0";
              load-mode = "none";
            };
            "unsloth/Qwen3.8-27B-GGUF:Q4_K_M" = {
              model = modelPath "unsloth/Qwen3.8-27B-GGUF" "Qwen3.8-27B-UD-Q4_K_M.gguf";
              mmproj = modelPath "unsloth/Qwen3.8-27B-GGUF" "mmproj-F16.gguf";
              # vision is rare; encoding on the cpu frees vram for context
              mmproj-offload = false;
              spec-draft-model = modelPath "unsloth/Qwen3.8-27B-GGUF" "MTP/mtp-Qwen3.8-27B-Q4_0.gguf";
              alias = "qwen3.8-27b-mtp";
              # one slot per hermes instance, both drawing on the shared 90k
              ctx-size = 92160;
              parallel = 2;
              kv-unified = true;
              n-gpu-layers = 999;
              temp = 1.0;
              top-p = 0.95;
              top-k = 20;
              min-p = 0.00;
              presence-penalty = 0.0;
              reasoning = "on";
              chat-template-kwargs = builtins.toJSON {
                reasoning_effort = "low";
                preserve_thinking = false;
              };
              spec-type = "draft-mtp";
              spec-draft-n-max = 2;
            };
            "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:Q4_K_XL" = {
              model = modelPath "unsloth/Qwen3.6-35B-A3B-MTP-GGUF" "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";
              mmproj = modelPath "unsloth/Qwen3.6-35B-A3B-MTP-GGUF" "mmproj-F16.gguf";
              alias = "qwen3.6-35b-a3b-mtp";
              # 2 slots of 122880 each; kv is only unified when parallel is auto.
              # fit offloads 12 expert layers, peak 23136/24467 MiB with a 4k image.
              # ubatch 2048 cuts per-chunk expert copies over pcie: +68% prompt speed
              ctx-size = 245760;
              parallel = 2;
              ubatch-size = 2048;
              temp = 1.0;
              top-p = 0.95;
              top-k = 20;
              min-p = 0.00;
              reasoning = "on";
              chat-template-kwargs = builtins.toJSON {
                preserve_thinking = false;
              };
              spec-type = "draft-mtp";
              spec-draft-n-max = 2;
            };
            "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:Q6_K" = {
              model = modelPath "unsloth/Qwen3.6-35B-A3B-MTP-GGUF" "Qwen3.6-35B-A3B-UD-Q6_K.gguf";
              mmproj = modelPath "unsloth/Qwen3.6-35B-A3B-MTP-GGUF" "mmproj-F16.gguf";
              alias = "qwen3.6-35b-a3b-q6k-mtp";
              # fit offloads 18 expert layers, peak 23068/24467 MiB with a 4k image
              ctx-size = 163840;
              parallel = 2;
              ubatch-size = 2048;
              temp = 1.0;
              top-p = 0.95;
              top-k = 20;
              min-p = 0.00;
              reasoning = "on";
              chat-template-kwargs = builtins.toJSON {
                preserve_thinking = false;
              };
              spec-type = "draft-mtp";
              spec-draft-n-max = 2;
            };
            "Hob-forge/Kolibri-1-GGUF:Q4_K_M" = {
              model = modelPath "Hob-forge/Kolibri-1-GGUF" "Kolibri-1-Q4_K_M.gguf";
              alias = startupModelAlias;
              load-on-startup = true;
              # attention and kv stay on the 4000; only routed experts move to
              # the arc b50 in nixworker and the cpu. fit would instead put
              # whole layers on the b50 behind the network
              rpc = "${flake-self.hosts.nixworker.direct}:${toString rpcPort}";
              device = "CUDA0,RPC0";
              tensor-split = "1,0";
              n-gpu-layers = 999;
              override-tensor = lib.concatStringsSep "," [
                "blk\\.(2[2-9]|3[0-3])\\.ffn_(up|down|gate)_exps=RPC0[${flake-self.hosts.nixworker.direct}:${toString rpcPort}]"
                "blk\\.(3[4-9]|4[0-9])\\.ffn_(up|down|gate)_exps=CPU"
              ];
              fit = "off";
              temp = 1.0;
              top-p = 0.97;
              top-k = 128;
              reasoning = "on";
            };
            "ggml-org/Laya-GGUF:Q8_0" = {
              model = modelPath "ggml-org/Laya-GGUF" "Laya-Q8_0.gguf";
              alias = "laya";
              # runs on the arc b50 in nixworker (llamaCppRpcServer); the child
              # still opens a cuda context of ~220 MiB here
              rpc = "${flake-self.hosts.nixworker.direct}:${toString rpcPort}";
              device = "RPC0";
              n-gpu-layers = 999;
              # laya evaluates a whole prompt in one ubatch, so ubatch caps the
              # state; 8192 is the model's context length
              ctx-size = 8192;
              batch-size = 8192;
              ubatch-size = 8192;
              parallel = 1;
            };
          };
        };
      };

      users.users.llama-cpp-models = {
        isSystemUser = true;
        group = "llama-cpp-models";
      };
      users.groups.llama-cpp-models = { };

      systemd.services.llama-cpp-models = {
        description = "download pinned llama.cpp models";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = [ pkgs.curl ];
        serviceConfig = {
          Type = "exec";
          User = "llama-cpp-models";
          Group = "llama-cpp-models";
          StateDirectory = "llama-cpp-models";
          TimeoutStartSec = "infinity";
          NoNewPrivileges = true;
          CapabilityBoundingSet = "";
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
          ];
        };
        script = ''
          while read -r repo file rev sha256; do
            dst="${modelsDir}/$repo/$file"
            [ -e "$dst" ] && continue
            mkdir -p "$(dirname "$dst")"

            curl --fail --location --retry 5 --retry-delay 10 --continue-at - \
              --output "$dst.part" "https://huggingface.co/$repo/resolve/$rev/$file"
            echo "$sha256  $dst.part" | sha256sum -c -
            mv "$dst.part" "$dst"
          done < ${manifest}

          # prune models that left the manifest; .part files stay for resume
          find ${modelsDir} -type f ! -name '*.part' | while read -r f; do
            grep -qxF "''${f#${modelsDir}/}" ${keepList} || rm -v "$f"
          done
          find ${modelsDir} -type d -empty -delete
        '';
      };

      services.homepage-dashboard.services = [
        {
          "llm" = [
            {
              "llama.cpp" = {
                href = "https://${localHost}";
                icon = "sh-llama-cpp";
                siteMonitor = "${listenUrl}/health";
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "llama.cpp";
          url = "https://${localHost}/health";
          enabled = true;
          alerts = [ { type = "matrix"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      # the router answers /metrics only for a named model instance
      services.telegraf.extraConfig.inputs.prometheus = [
        {
          urls = [ "${listenUrl}/metrics?model=${startupModelAlias}" ];
          metric_version = 2;
          fieldinclude = [ "llamacpp:*" ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';
    };

  # exposes the arc gpu to the nixbox llama-cpp router over ggml rpc
  flake.modules.nixos.llamaCppRpcServer =
    {
      config,
      flake-self,
      pkgs,
      ...
    }:
    let
      package = pinned pkgs (
        pkgs.llama-cpp.override {
          vulkanSupport = true;
          rpcSupport = true;
        }
      );
      listenAddress = flake-self.hosts.${config.networking.hostName}.direct;
    in
    {
      systemd.services.ggml-rpc-server = {
        description = "ggml rpc server for the llama-cpp router";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        # only the intel icd, so the amd igpu is not exposed and the arc is Vulkan0
        environment = {
          VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json";
          LLAMA_CACHE = "/var/cache/ggml-rpc-server";
          XDG_CACHE_HOME = "/var/cache/ggml-rpc-server";
        };
        serviceConfig = {
          ExecStart = "${package}/bin/ggml-rpc-server --host ${listenAddress} --port ${toString rpcPort} --device Vulkan0 --cache";
          DynamicUser = true;
          SupplementaryGroups = [ "render" ];
          CacheDirectory = "ggml-rpc-server";
          Restart = "on-failure";
          RestartSec = 5;

          CapabilityBoundingSet = "";
          DeviceAllow = [ "char-drm rw" ];
          DevicePolicy = "closed";
          LockPersonality = true;
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectSystem = "strict";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
            "AF_NETLINK"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
          ];
          UMask = "0077";
        };
      };

      # rpc has no authentication; only the router host may connect
      networking.firewall.extraInputRules = ''
        ip saddr ${flake-self.hosts.nixbox.direct} tcp dport ${toString rpcPort} accept
      '';
    };
}
