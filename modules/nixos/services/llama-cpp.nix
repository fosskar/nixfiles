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
        "unsloth/Qwen3.6-27B-GGUF" = {
          file = "Qwen3.6-27B-UD-Q4_K_XL.gguf";
          rev = "82d411acf4a06cfb8d9b073a5211bf410bfc29bf";
          sha256 = "ff6941ded525b34eb159496762c29dd0ec6e71dc31b74d57e75d871a03eec259";
        };
        "unsloth/Qwen3.6-27B-MTP-GGUF" = {
          file = "Qwen3.6-27B-UD-Q4_K_XL.gguf";
          rev = "5cb35eb3dcbf52dbce5f87dbc64df6aaffadcace";
          sha256 = "4085665ee36d82a672a238a43f0e5643f2f0e39f2d7bd5d373f0ef10ecf53095";
        };
        "unsloth/Qwen3.6-35B-A3B-MTP-GGUF" = {
          file = "Qwen3.6-35B-A3B-UD-IQ4_XS.gguf";
          rev = "5bc3e238d916f48a861bac2f8a1990a0e9b7e98d";
          sha256 = "df27a780435b7b45c2597536112ea3cb091f8544c3d0c3318d9f4258b31f7adf";
        };
      };
      modelPath = repo: "${modelsDir}/${repo}/${models.${repo}.file}";
      manifest = pkgs.writeText "llama-cpp-models.manifest" (
        lib.concatMapStrings (
          repo: "${repo} ${models.${repo}.file} ${models.${repo}.rev} ${models.${repo}.sha256}\n"
        ) (lib.attrNames models)
      );
      keepList = pkgs.writeText "llama-cpp-models.keep" (
        lib.concatMapStrings (repo: "${repo}/${models.${repo}.file}\n") (lib.attrNames models)
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
            "unsloth/Qwen3.6-27B-GGUF:Q4_K_XL" = {
              model = modelPath "unsloth/Qwen3.6-27B-GGUF";
              alias = "qwen3.6-27b";
              temp = 0.7;
              top-p = 0.8;
              top-k = 20;
              presence-penalty = 1.5;
              min-p = 0.00;
              reasoning = "off";
            };
            "unsloth/Qwen3.6-27B-MTP-GGUF:Q4_K_XL" = {
              model = modelPath "unsloth/Qwen3.6-27B-MTP-GGUF";
              alias = "qwen3.6-27b-mtp";
              ctx-size = 65536;
              cache-type-v = "q4_0";
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
              cache-type-k-draft = "q4_0";
              cache-type-v-draft = "q4_0";
            };
            "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:IQ4_XS" = {
              model = modelPath "unsloth/Qwen3.6-35B-A3B-MTP-GGUF";
              alias = "qwen3.6-35b-a3b-mtp";
              load-on-startup = true;
              ctx-size = 131072;
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
              cache-type-k-draft = "q4_0";
              cache-type-v-draft = "q4_0";
            };
          };
        };
      };

      systemd.services.llama-cpp-models = {
        description = "download pinned llama.cpp models";
        wantedBy = [ "llama-cpp.service" ];
        before = [ "llama-cpp.service" ];
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
