{ pkgs, ... }:
let
  qwen3Model = pkgs.fetchurl {
    url = "https://huggingface.co/Qwen/Qwen3-14B-GGUF/resolve/main/Qwen3-14B-Q5_K_M.gguf";
    sha256 = "sha256-58mroRKcopNr6eygFBnZ+Gr0DgjKoBIw1VdLNNCOPjE=0000000";
  };
in
{
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
    oci-containers = {
      backend = "podman";
      containers = {
        ipex-llm = {
          autoStart = true;
          image = "intelanalytics/ipex-llm-inference-cpp-xpu:latest";

          ports = [
            "11434:11434"
          ];

          volumes = [
            "${qwen3Model}:/models/qwen3-14b.gguf:ro"
          ];
          environment = {
            SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS = "1";
            ONEAPI_DEVICE_SELECTOR = "level_zero:0";
            no_proxy = "localhost,127.0.0.1";
            DEVICE = "Arc";
            ZES_ENABLE_SYSMAN = "1";
            OLLAMA_HOST = "127.0.0.1:11434";
            OLLAMA_NUM_GPU = "999";
            OLLAMA_INTEL_GPU = "true";
          };
          cmd = [
            "/bin/sh"
            "-c"
            "/llm/scripts/start-ollama.sh && echo 'Startup script finished, container is now idling.' && sleep infinity"
          ];
          extraOptions = [
            "--net=host"
            "--memory=32G"
            "--shm-size=16g"
            "--device=/dev/dri/renderD128:/dev/dri/renderD128"
            "--group-add=303"
          ];
        };
      };
    };
  };

  # create ollama directory
  systemd.tmpfiles.rules = [
    "d /var/lib/ollama 0755 root root -"
  ];

  # create group with same GID as proxmox for device access
  users.groups.proxmox-render = {
    gid = 993;
  };

  # fix device ownership on boot
  systemd.services.fix-dri-permissions = {
    description = "fix /dev/dri permissions for podman";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/chgrp 303 /dev/dri/renderD128";
    };
  };

  networking.firewall.allowedTCPPorts = [ 11434 ];
}
