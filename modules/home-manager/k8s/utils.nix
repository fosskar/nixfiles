_: {
  flake.modules.homeManager.k8s =
    { pkgs, ... }:
    {
      home.packages = [
        # helm wrapped with the only plugins worth having: diff for previewing
        # upgrades (helmfile needs it too), secrets to inline sops values
        (pkgs.wrapHelm pkgs.kubernetes-helm {
          plugins = with pkgs.kubernetes-helmPlugins; [
            helm-diff
            helm-secrets
          ];
        })
        pkgs.kubectl
        pkgs.kubecolor
        pkgs.kubectx
        pkgs.kubelogin
        pkgs.kubeseal
        pkgs.talosctl
        pkgs.clusterctl

        # observability and inspection depth k9s doesn't cover
        pkgs.stern
        pkgs.kubectl-tree
        pkgs.kubectl-view-secret

        # offline validation and RBAC/access tooling
        pkgs.kubeconform
        pkgs.rakkess
        pkgs.kubectl-node-shell
      ];

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
