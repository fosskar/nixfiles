{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    k9s
    argo
    dive
    kubectl
    kubernetes-helm
    cilium-cli
    clusterctl
    skopeo
  ];

  services.k3sManaged = {
    enable = true;
    role = "agent";
    nodeIP = "10.0.0.4";
    serverAddr = "10.0.0.2";
    tokenFile = config.sops.secrets."k8s/k3s-nixos".path;
  };
}
