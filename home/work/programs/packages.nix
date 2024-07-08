{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # music
    spotify

    # notes
    obsidian
    libreoffice
    kdePackages.okular

    # communication
    slack
    evolutionWithPlugins

    # virt
    virt-manager

    # cli
    yq
    nh
    toybox
    nettools

    # Audio
    pavucontrol
    playerctl
    pamixer

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
    bitwarden-desktop
    kubecm
    cosign

    # misc
    brightnessctl
  ];
}
