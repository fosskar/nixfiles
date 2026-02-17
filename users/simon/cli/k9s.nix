{ pkgs, ... }:
{
  home.packages = with pkgs; [
    helmfile
    kubecolor
    kubectl
    kubectx
    kubelogin
    kubernetes-helm
    kubeseal
    talosctl
    clusterctl
  ];

  programs.k9s = {
    enable = true;

    settings.k9s = {
      ui = {
        enableMouse = false; # can scroll, but dont click. true = cant scroll, but can click
      };
      liveViewAutoRefresh = true;
      refreshRate = 1;
      maxConnRetry = 3;
    };
  };

  home.shellAliases = {
    # kubectl
    k = "kubecolor";
    kc = "kubectx";
    kn = "kubens";
    ks = "kubeseal";
    kubectl = "kubecolor";
    kcs = "kubectl config use-context $(kubectl config get-contexts --output=name | fzf)";
  };
}
