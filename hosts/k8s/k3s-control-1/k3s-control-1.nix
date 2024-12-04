{ config, ... }:
{
  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = config.sops.secrets."k8s/k3s-nixos".path;
    extraFlags = [
      "--node-name=k3s-control-1"
      "--data-dir=/var/lib/rancher/k3s"
      "--node-ip=10.0.0.2"
      "--write-kubeconfig=/root/.kube/config"
      "--write-kubeconfig-mode 0644"
      "--cluster-cidr 10.42.0.0/16"
      "--service-cidr 10.43.0.0/16"
      "--kube-scheduler-arg bind-address=0.0.0.0"
      "--kube-controller-manager-arg bind-address=0.0.0.0"
      #"--disable traefik"
      #"--disable servicelb"
      #"--flannel-backend=none"
      #"--disable-network-policy"
      #"--disable metrics-server"
      #"--disable local-storage"
      #"--disable-kube-proxy"
      #"--disable-cloud-controller"
      #"--kubelet-arg=register-with-taints=node.cilium.io/agent-not-ready:NoExecute"
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
            version = "7.7.7";
            targetNamespace = "argocd";
            createNamespace = true;
            bootstrap = true;
            valuesContent = ''
              global:
                domain: argocd.simonoscar.me
              configs:
                cm:
                  statusbadge.enabled: true
                params:
                  server.insecure: true
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
                  ingressClassName: traefik
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
    };

    #manifests = {
    #  cilium = {
    #    enable = true;
    #    target = "cilium.yaml";
    #    content = {
    #      apiVersion = "helm.cattle.io/v1";
    #      kind = "HelmChart";
    #      metadata = {
    #        name = "cilium";
    #        namespace = "kube-system";
    #      };
    #      spec = {
    #        repo = "https://helm.cilium.io";
    #        chart = "cilium";
    #        version = "1.16.3";
    #        targetNamespace = "kube-system";
    #        valuesContent = ''
    #          operator:
    #            replicas: 1
    #          ipam:
    #            mode: "kubernetes"
    #            operator:
    #              clusterPoolIPv4PodCIDRList: ["10.42.0.0/16"]
    #          k8sServiceHost: "10.0.0.2"
    #          k8sServicePort: 6443
    #          cni:
    #            binPath: "/var/lib/rancher/k3s/agent/opt/cni/bin"
    #            confPath: "/var/lib/rancher/k3s/agent/etc/cni/net.d"
    #        '';
    #      };
    #    };
    #  };
    #};
  };
  #networking.firewall = {
  #  enable = true;
  #  # NOTE: `loose` required for cilium when using without kube-proxy replacement to get working livenes probe for pods. With this settings the cluster is mostly usable with exception of
  #  # Cilium DNS Filtering: msg="Timeout waiting for response to forwarded proxied DNS lookup" dnsName=vpn-gateway-pod-gateway.vpn-gateway.svc.cluster.local. error="read udp 10.42.0.183:43844->10.42.0.176:53: i/o timeout" ipAddr="10.42.0.183:43844" subsys=fqdn/dnsproxy
  #  # => Therefore we have to use `checkReversePath=false` to get our vpn-gateway CiliumNetworkPolicy with DNS Filter working (when installing without cilium kube-proxy replacement).
  #  checkReversePath = false;
  #};
}
