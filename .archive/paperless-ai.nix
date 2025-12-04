{ config, ... }:
{
  virtualisation.oci-containers = {
    backend = "podman";
    containers.paperless-ai = {
      image = "docker.io/clusterzx/paperless-ai:latest";
      autoStart = true;

      environment = {
        PAPERLESS_AI_PORT = "5005";
        PAPERLESS_URL = "http://10.0.0.108:28981";
        OLLAMA_HOST = "http://10.0.0.106:11434";
        #PAPERLESS_API_TOKEN=your-token
        #
        OLLAMA_KEEP_ALIVE = "-1";
      };

      environmentFiles = [ config.sops.secrets."paperless.env".path ];

      log-driver = "journald";

      volumes = [
        "/var/lib/paperless-ai:/app/data:U"
      ];

      extraOptions = [
        "--pull=newer"
        "--network=host"
        "--cap-drop=ALL"
        "--security-opt=no-new-privileges=true"
      ];
    };
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/paperless-ai 0755 root root -"
  ];

  networking.firewall.allowedTCPPorts = [ 5005 ];
}
