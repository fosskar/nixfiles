{
  imports = [
    ../../../modules/kubernetes/helm.nix
  ];
  system.k3s.helm.enable = true;
  system.k3s.helm.charts = {
    argocd = {
      chart = "argo-cd";
      namespace = "argocd";
      version = "7.1.0";
      repo = "https://argoproj.github.io/argo-helm";
      valuesYaml = ''
        global:
          domain: argocd.space
        configs:
          params:
            applicationsetcontroller.enable.progressive.syncs: true
            server.insecure: true
          repositories:
            gitops-boostrap:
              url: https://gitlab.com/simonoscr/gitops-bootstrap.git
              name: gitlab.com/simonoscr
              type: git
        server:
          ingress:
            enabled: true
            annotations:
              traefik.ingress.kubernetes.io/router.entrypoints: web
            ingressClassName: "traefik"
            tls: false
      '';
    };
  };
}
