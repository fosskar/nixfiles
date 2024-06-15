{
  imports = [
    ../../../../modules/nixos/kubernetes/helm.nix
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
        dex:
          enabled: false
        server:
          ingress:
            enabled: true
            annotations:
              traefik.ingress.kubernetes.io/router.entrypoints: web
            ingressClassName: "traefik"
            tls: false
      '';
    };
    # for bootstrap repository
    argocd-apps = {
      chart = "argocd-apps";
      namespace = "argocd";
      version = "2.0.0";
      repo = "https://argoproj.github.io/argo-helm";
      valuesYaml = ''
        applications:
          bootstrap:
            namespace: argocd
            finalizers:
            - resources-finalizer.argocd.argoproj.io
            project: argocd
            sources:
            - repoURL: https://gitlab.com/simonoscr/gitops-bootstrap.git
              path: bootstrap
              targetRevision: HEAD
            destination:
              server: https://kubernetes.default.svc
              namespace: argocd
            syncPolicy:
              automated:
                prune: true
                selfHeal: true
              syncOptions:
              - CreateNamespace=true
        projects:
          argocd:
            namespace: argocd
            permitOnlyProjectScopedClusters: false
            finalizers:
            - resources-finalizer.argocd.argoproj.io
            description: ArgoCD Bootstrap Project
            sourceRepos:
            - "*"
            destinations:
            - namespace: argocd
              server: https://kubernetes.default.svc
            #clusterResourceWhitelist: []
            #clusterResourceBlacklist: []
            #namespaceResourceBlacklist:
            #- group: ""
            #  kind: ResourceQuota
            #- group: ""
            #  kind: LimitRange
            #- group: ""
            #  kind: NetworkPolicy
            #  orphanedResources: {}
            #  roles: []
            #namespaceResourceWhitelist:
            #- group: "apps"
            #  kind: Deployment
            #- group: "apps"
            #  kind: StatefulSet
            orphanedResources: {}
            roles: []
            sourceNamespaces:
            - argocd
      '';
    };
    #cilium = {
    #  chart = "cilium";
    #  namespace = "kube-system";
    #  version = "1.15.1";
    #  repo = "https://helm.cilium.io";
    #  valuesYaml = ''
    #  '';
    #};
  };
}
