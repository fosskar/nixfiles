{ config, ... }:
{
  # read through flake-self by consumers on other hosts, such as silo
  flake.whisperServer = {
    port = 8178;
    url = "http://${config.flake.hosts.nixworker.lan}:${toString config.flake.whisperServer.port}";
    # the server loads one model and ignores the name a request sends
    model = "whisper-large-v3-turbo";
  };

  # openai-style speech-to-text with timed segments, on the arc gpu
  flake.modules.nixos.whisperServer =
    {
      config,
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (flake-self.whisperServer) port;
      listenAddress = flake-self.hosts.${config.networking.hostName}.lan;
      model = pkgs.fetchurl {
        url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/5359861c739e955e79d9a303bcbc70fb988958b1/ggml-large-v3-turbo.bin";
        hash = "sha256-H8cPd0046xaZk6w5Huo1fvR8iHV+9y7llDh5t+jivGk=";
      };
    in
    {
      systemd.services.whisper-server = {
        description = "whisper.cpp speech-to-text server";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        # only the intel icd, so the amd igpu is not exposed and the arc is Vulkan0
        environment.VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json";
        serviceConfig = {
          # no --vad: with it the word times stay on the vad-compressed
          # timeline while segment times do not, and silo cuts cues by word
          ExecStart = lib.escapeShellArgs [
            (lib.getExe' pkgs.whisper-cpp-vulkan "whisper-server")
            "--model"
            model
            "--language"
            "auto"
            "--host"
            listenAddress
            "--port"
            (toString port)
            "--inference-path"
            "/v1/audio/transcriptions"
          ];
          DynamicUser = true;
          SupplementaryGroups = [ "render" ];
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

      # no authentication, and /load reads any model path; only silo's host
      # may connect
      networking.firewall.extraInputRules = ''
        ip saddr ${flake-self.hosts.nixbox.lan} tcp dport ${toString port} accept
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
