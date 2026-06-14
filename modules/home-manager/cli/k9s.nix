_: {
  flake.modules.homeManager.k9s =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.helmfile
        pkgs.kubecolor
        pkgs.kubectl
        pkgs.kubectx
        pkgs.kubelogin
        pkgs.kubernetes-helm
        pkgs.kubeseal
        pkgs.talosctl
        pkgs.clusterctl
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
    };
}
