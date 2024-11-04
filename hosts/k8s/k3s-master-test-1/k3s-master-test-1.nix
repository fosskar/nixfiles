{ pkgs, ... }:
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
    role = "server";
    clusterInit = true;
    nodeIP = "10.0.0.2";
    #tokenFile = config.sops.secrets."k8s/k3s-nixos".path; # doesnt work with auto created CA because thats part of the secret and changes on cluster reset
    clusterDomain = "k3s-nixos.space";
    disableTraefik = false;
    disableFlannel = false;
    disableServicelb = false;
    disableKubeProxy = false;
  };
}
