{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # music
    spotify

    # notes
    obsidian
    libreoffice

    # communication
    thunderbird-bin
    slack
    (zoom-us.override { gnomeXdgDesktopPortalSupport = true; })
    #(pkgs.zoom-us.overrideAttrs {
    #  version = "6.5.11.62892";
    #  src = pkgs.fetchurl {
    #    url = "https://zoom.us/client/6.5.11.62892/zoom_x86_64.pkg.tar.xz";
    #    hash = "sha256-KTg6VO1GT/8ppXFevGDx0br9JGl9rdUtuBzHmnjiOuk=";
    #  };
    #})

    #samba4Full

    nautilus

    # cli
    yq-go
    dive
    apacheHttpd

    # archive
    zip
    unzip
    unrar
    unar

    # devops tools
    kubectl
    kubectl-tree
    kubectl-neat
    kubectl-ktop
    kubectl-klock
    kubectl-images
    kubectl-gadget
    kubectl-view-secret
    kubectl-view-allocations
    kubecolor
    kubelogin-oidc
    kubernetes-helm
    argocd
    ansible
    #(python311.withPackages (ps: [
    #  ps.ansible
    #  ps.pip
    #  ps.lxml
    #  ps.dnspython
    #  ps.click
    #  ps.six
    #  ps.pynacl
    #]))
    vault
    #vagrant
    #molecule
    minikube
    minio-client
    glab # gitlab api cli

    # security
    #keepassxc
    #git-credential-keepassxc
    bitwarden-desktop
    kubecm

    # nix
    cachix
  ];
}
