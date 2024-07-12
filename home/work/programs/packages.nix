{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # music
    spotify

    # notes
    obsidian
    libreoffice

    # communication
    slack

    # cli
    yq
    toybox
    nettools

    # devops tools
    kubectl
    kubelogin-oidc
    kubernetes-helm
    argocd
    fluxctl
    ansible
    vault
    vagrant
    minikube
    minio-client

    # security
    keepassxc
    git-credential-keepassxc
    #bitwarden-desktop
    kubecm
    cosign

    # misc
    brightnessctl
  ];
}
