{ config, ... }:
{
  # read through flake-self by consumers such as silo
  flake.whisperServer = {
    port = 8178;
    url = "http://127.0.0.1:${toString config.flake.whisperServer.port}";
    # the server loads one model and ignores the name a request sends
    model = "whisper-large-v3-turbo";
  };

  # openai-style speech-to-text with whole words and word times, on the
  # nvidia gpu. whisper.cpp returns sub-word tokens as words, which silo
  # joins with spaces
  flake.modules.nixos.whisperServer =
    {
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (flake-self.whisperServer) port;
      # plain nixpkgs with cuda: the nixos-cuda cache has these builds. this
      # host's own cuda package set would compile onnxruntime, opencv and more
      cudaPkgs = import pkgs.path {
        inherit (pkgs.stdenv.hostPlatform) system;
        config = {
          allowUnfree = true;
          cudaSupport = true;
        };
      };
      server = cudaPkgs.writers.writePython3Bin "whisper-server" {
        libraries = [
          cudaPkgs.python3Packages.faster-whisper
          cudaPkgs.python3Packages.fastapi
          cudaPkgs.python3Packages.python-multipart
          cudaPkgs.python3Packages.uvicorn
        ];
      } (builtins.readFile ./whisper-server.py);
      modelRepo = "https://huggingface.co/mobiuslabsgmbh/faster-whisper-large-v3-turbo/resolve/0a363e9161cbc7ed1431c9597a8ceaf0c4f78fcf";
      model = pkgs.linkFarm "faster-whisper-large-v3-turbo" (
        lib.mapAttrs
          (
            name: hash:
            pkgs.fetchurl {
              url = "${modelRepo}/${name}";
              inherit hash;
            }
          )
          {
            "config.json" = "sha256-sCU+psDTvqax4Z6RoCrP07U/RGc2Lvy1o+axbJs6m34=";
            "model.bin" = "sha256-52Yg+D1fW2nv09h+PcGAwb0h35++us/UM15eHvzAGNo=";
            "preprocessor_config.json" = "sha256-fMxixvJ2WvHztGwAybWJRCaDWgUCHIucAe7LbftUJxE=";
            "tokenizer.json" = "sha256-KXsTNyrEORYoVkT7loet08xi7ioa22DaPcJcyUwYcf0=";
            "vocabulary.json" = "sha256-xpJg8qsm1lm3w5j5orK0jtDfFsO0fXMmeC/Zy6cWkME=";
          }
      );
    in
    {
      systemd.services.whisper-server = {
        description = "faster-whisper speech-to-text server";
        wantedBy = [ "multi-user.target" ];
        environment = {
          WHISPER_HOST = "127.0.0.1";
          WHISPER_PORT = toString port;
          WHISPER_MODEL = model;
          # the model takes 1356 MiB of the 2932 MiB llama-cpp leaves free,
          # and a 4k transcode up to 1390 MiB; it loads in 2 s
          WHISPER_IDLE_SECONDS = "60";
        };
        serviceConfig = {
          ExecStart = lib.getExe server;
          DynamicUser = true;
          # the server exits when idle to free the vram
          Restart = "always";
          RestartSec = 1;

          CapabilityBoundingSet = "";
          DeviceAllow = [
            "char-nvidia-uvm"
            "char-nvidia-frontend"
            "char-nvidia-caps"
            "char-nvidiactl"
          ];
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

      # the hermes sandboxes reach nixbox only on :443
      services.caddy.virtualHosts."whisper.${flake-self.domains.local}".extraConfig = ''
        reverse_proxy ${flake-self.whisperServer.url}
      '';

      services.gatus.settings.endpoints = [
        {
          name = "Whisper Server";
          url = "${flake-self.whisperServer.url}/health";
          conditions = [ "[STATUS] == 200" ];
          enabled = true;
          alerts = [ { type = "matrix"; } ];
          interval = "5m";
        }
      ];
    };
}
