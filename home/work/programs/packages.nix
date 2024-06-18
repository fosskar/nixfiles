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
    evolution

    # virt
    virt-manager

    # cli
    yq

    # Audio
    pavucontrol
    playerctl
    pamixer

    # devops tools
    kubectl
    kubernetes-helm
    argocd
    fluxctl
    ansible
    vault
    minikube
    podman

    # security
    keepassxc
    git-credential-keepassxc
    bitwarden-desktop
    kubecm
  ];
}
