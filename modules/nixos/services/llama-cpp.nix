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
      modelsDir = "/var/lib/llama-cpp-models";
      # pinned to immutable HF revisions: resolve/main lets upstream re-upload
      # weights in place, and llama.cpp's etag check then silently re-downloads
      # the swapped file on the next model load
      models = {
        "unsloth/Qwen3.6-27B-MTP-GGUF" = {
          rev = "5cb35eb3dcbf52dbce5f87dbc64df6aaffadcace";
          files = {
            "Qwen3.6-27B-IQ4_XS.gguf" = "89f2c7e4f9f91d17ba9df6f0eef67cb909bc67d91cd035291be35cd88f1848ba";
            "mmproj-F16.gguf" = "eacf610d1ee4bd5ed0197a0777dd8f4fceb8eefa27009067c7d496cb68fbde45";
          };
        };
        "unsloth/Qwen3.6-35B-A3B-MTP-GGUF" = {
          rev = "5bc3e238d916f48a861bac2f8a1990a0e9b7e98d";
          files = {
            "Qwen3.6-35B-A3B-UD-IQ4_XS.gguf" =
              "df27a780435b7b45c2597536112ea3cb091f8544c3d0c3318d9f4258b31f7adf";
            "mmproj-F16.gguf" = "71f3cbc1f7cc0f30d09d41cfa924c0060827ebc33bf15ace7e86661e856f0160";
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
            "unsloth/Qwen3.6-27B-MTP-GGUF:IQ4_XS" = {
              model = modelPath "unsloth/Qwen3.6-27B-MTP-GGUF" "Qwen3.6-27B-IQ4_XS.gguf";
              mmproj = modelPath "unsloth/Qwen3.6-27B-MTP-GGUF" "mmproj-F16.gguf";
              alias = "qwen3.6-27b-mtp";
              # 96k + gpu mmproj measured at 22.0/24.5 GiB; 131k leaves no room for image encode
              ctx-size = 98304;
              temp = 0.7;
              top-p = 0.8;
              top-k = 20;
              min-p = 0.00;
              presence-penalty = 1.5;
              reasoning = "off";
              chat-template-kwargs = builtins.toJSON {
                enable_thinking = false;
              };
              spec-type = "draft-mtp";
              spec-draft-n-max = 2;
            };
            "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:IQ4_XS" = {
              model = modelPath "unsloth/Qwen3.6-35B-A3B-MTP-GGUF" "Qwen3.6-35B-A3B-UD-IQ4_XS.gguf";
              mmproj = modelPath "unsloth/Qwen3.6-35B-A3B-MTP-GGUF" "mmproj-F16.gguf";
              alias = "qwen3.6-35b-a3b-mtp";
              load-on-startup = true;
              # unverified: 96k chosen over 131k to make room for the gpu mmproj;
              # confirm fit on first load with an image request before raising
              ctx-size = 98304;
              temp = 1.0;
              top-p = 0.95;
              top-k = 20;
              min-p = 0.00;
              reasoning = "on";
              chat-template-kwargs = builtins.toJSON {
                preserve_thinking = false;
              };
              spec-type = "draft-mtp";
              spec-draft-n-max = 3;
            };
          };
        };
      };

      systemd.services.llama-cpp-models = {
        description = "download pinned llama.cpp models";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = [ pkgs.curl ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          StateDirectory = "llama-cpp-models";
          TimeoutStartSec = "infinity";
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
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';
    };
}
