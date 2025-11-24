_: {
  k3s.controlPlane = {
    enable = true;
    clusterInit = true;
    nodeName = "k3s-control-1";
    nodeIp = "10.0.0.2";
    tlsSans = [ "k3s.simonoscar.me" ];
  };

  services.k3s.manifests = {
    argo-cd = {
      enable = true;
      target = "argocd.yaml";
      content = {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChart";
        metadata = {
          name = "argocd";
          namespace = "kube-system";
        };
        spec = {
          repo = "https://argoproj.github.io/argo-helm";
          chart = "argo-cd";
          version = "7.8.2";
          targetNamespace = "argocd";
          createNamespace = true;
          bootstrap = true;
          valuesContent = ''
            global:
              domain: argocd.simonoscar.me
            configs:
              cm:
                create: true
                statusbadge.enabled: true
                oidc.config: |
                  name: Authentik
                  issuer: https://auth.simonoscar.me/application/o/argocd/
                  clientID: argocd
                  requestedScopes: ["openid", "profile", "email", "groups"]
                  enablePKCEAuthentication: true
              rbac:
                policy.csv: |
                  g, authentik Admins, role:admin
              params:
                #server.enable.proxy.extension: true
                #controller.diff.server.side: true
                applicationsetcontroller.enable.progressive.syncs: true
              repositories:
                gitops-repo:
                  url: "https://gitlab.com/simonoscr/gitops.git"
                  name: gitlab.com/simonoscr/gitops
                  type: git
            dex:
              enabled: false
            server:
              ingress:
                enabled: true
                annotations:
                  cert-manager.io/cluster-issuer: tls-issuer
                  nginx.ingress.kubernetes.io/ssl-passthrough: "true"
                  nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
                ingressClassName: nginx
                hostname: argocd.simonoscar.me
                tls: true
            notifications:
              enabled: false
          '';
        };
      };
    };
    argocd-apps = {
      enable = true;
      target = "argocd-apps.yaml";
      content = {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChart";
        metadata = {
          name = "argocd-apps";
          namespace = "kube-system";
        };
        spec = {
          repo = "https://argoproj.github.io/argo-helm";
          chart = "argocd-apps";
          version = "2.0.2";
          targetNamespace = "argocd";
          bootstrap = true;
          valuesContent = ''
            applications:
              bootstrap:
                namespace: argocd
                finalizers:
                - resources-finalizer.argocd.argoproj.io
                project: argocd
                sources:
                - repoURL: https://gitlab.com/simonoscr/gitops.git
                  path: bootstrap
                  targetRevision: HEAD
                destination:
                  server: https://kubernetes.default.svc
                  namespace: argocd
                syncPolicy:
                  automated:
                    prune: true
                    selfHeal: true
                revisionHistoryLimit: null
                info:
                - name: gitops
                  value: https://gitlab.com/simonoscr/gitops.git
            projects:
              argocd:
                namespace: argocd
                finalizers:
                - resources-finalizer.argocd.argoproj.io
                description: ArgoCD Bootstrap Project
                sourceRepos:
                - "https://gitlab.com/simonoscr/gitops.git"
                destinations:
                - namespace: argocd
                  server: https://kubernetes.default.svc
                sourceNamespaces:
                - argocd
          '';
        };
      };
    };
    cilium = {
      enable = true;
      target = "cilium.yaml";
      content = {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChart";
        metadata = {
          name = "cilium";
          namespace = "kube-system";
        };
        spec = {
          bootstrap = true;
          chart = "https://127.0.0.1:6443/static/charts/cilium.tgz";
          version = "1.17.1";
          targetNamespace = "kube-system";
          valuesContent = ''
            upgradeCompatibility: "1.17"
            kubeProxyReplacement: "true"
            k8sServiceHost: "127.0.0.1"
            k8sServicePort: 6443
            routingMode: "tunnel"
            tunnelProtocol: "geneve"
            ipam:
              operator:
                clusterPoolIPv4PodCIDRList: ["10.42.0.0/16"]
            encryption:
              enabled: true
              type: wireguard
              nodeEncryption: true
            #ingressController:
            #  enabled: true
            #  default: true
            #  enforceHttps: true
            #  loadbalancerMode: dedicated
            #  service:
            #    type: ClusterIP
            #    externalTrafficPolicy: "~"
            #  hostNetwork:
            #    enabled: true
            #    sharedListenerPort: 443
            #nodeIPAM:
            #  enabled: true
            #defaultLBServiceIPAM: nodeipam
            #socketLB:
            #  enabled: true
            #  hostNamespaceOnly: true
          '';
        };
      };
    };
  };

  # create symlinks to link k3s's cni directory to the one used by almost all CNI plugins
  # such as multus, calico, etc.
  # https://www.freedesktop.org/software/systemd/man/latest/tmpfiles.d.html#Type
  systemd.tmpfiles.rules = [
    "L+ /opt/cni/bin - - - - /var/lib/rancher/k3s/data/current/bin"
    # If you have disabled flannel, you will have to create the directory via a tmpfiles rule
    "d /var/lib/rancher/k3s/agent/etc/cni/net.d 0751 root root - -"
    # Link the CNI config directory
    "L+ /etc/cni/net.d - - - - /var/lib/rancher/k3s/agent/etc/cni/net.d"
  ];
}
