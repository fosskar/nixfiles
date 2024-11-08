{ config, ... }:
{
  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://10.0.0.2:6443";
    tokenFile = config.sops.secrets."k8s/k3s-nixos".path;
    extraFlags = [
      "--node-name k3s-worker-2"
      "--data-dir /var/lib/rancher/k3s"
      "--node-ip 10.0.0.4"
      "--node-label worker=true"
    ];
  };
}
