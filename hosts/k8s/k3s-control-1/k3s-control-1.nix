{
  config,
  pkgs,
  ...
}:
{
  services.k3s = {
    enable = true;
    role = "server";
    clusterInit = true;
    tokenFile = config.sops.secrets."k8s/k3s-nixos".path;
    extraFlags = [
      "--node-name=k3s-control-1"
      "--data-dir=/var/lib/rancher/k3s"
      "--node-ip=10.0.0.2"
      "--tls-san=10.0.0.2"
      "--tls-san=k3s.simonoscar.me"
      "--write-kubeconfig=/root/.kube/config"
      "--disable=traefik"
      "--disable-network-policy"
      "--disable=servicelb"
      "--flannel-backend=none"
      "--etcd-expose-metrics"
      "--secrets-encryption"
      "--disable-kube-proxy"
      "--egress-selector-mode=cluster"
      "--kube-scheduler-arg bind-address=0.0.0.0"
      "--kube-controller-manager-arg bind-address=0.0.0.0"
      #"--disable metrics-server"
      #"--disable local-storage"
      #"--disable-cloud-controller"
    ];

    manifests = {
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
                  statusbadge.enabled: true
                  dex.config: |
                    connectors:
                      - config:
                          issuer: https://auth.simonoscar.me/application/o/argocd/
                          clientID: argocd
                          clientSecret: "nCvUbTh7Jl3FMmRzKLcq6EHgRlRh8poqPp1NXTntmig9akmrTLRMvuaDObQEA2ygVHXFpppZotzN1biXrBdFuDv0bLWJt9N5tNl3JEKHluwAkUGcF55v01cRoeN5USTm"
                          insecureEnableGroups: true
                          scopes:
                            - openid
                            - profile
                            - email
                        name: authentik
                        type: oidc
                        id: authentik
                rbac:
                  policy.csv: |
                    g, authentik Admins, role:admin
                params:
                  applicationsetcontroller.enable.progressive.syncs: true
                repositories:
                  gitops-repo:
                    url: "https://gitlab.com/simonoscr/gitops.git"
                    name: gitlab.com/simonoscr/gitops
                    type: git
              controller:
                dynamicClusterDistribution: true
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
            version = "1.17.0";
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
              #externalIPs:
              #  enabled: true
              #envoy:
              #  enabled: true
              #  securityContext:
              #    capabilities:
              #      keepCapNetBindService: true
              #      envoy:
              #        - NET_ADMIN
              #        - NET_BIND_SERVICE
              #        - SYS_ADMIN
              #hostPort:
              #  enabled: true
              #nodePort:
              #  enabled: true
              debug:
                enabled: true
                verbose: enovy
            '';
          };
        };
      };
    };

    # Install Cilium before K3s starts
    charts = {
      cilium = pkgs.fetchurl {
        url = "https://helm.cilium.io/cilium-1.17.0.tgz"; # Fetch Helm chart
        sha256 = "sha256-cqggvwG7PgLAGFaJKgUI2pLfyUF0+HBce8tduxXiKP4="; # lib.fakeSha256; # Replace with actual sha256 from Helm repo
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
