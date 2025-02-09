{ config, pkgs, ... }:
{
  services.k3s = {
    enable = true;
    role = "server";
    serverAddr = "https://10.0.0.2:6443";
    tokenFile = config.sops.secrets."k8s/k3s-nixos".path;
    extraFlags = [
      "--node-name=k3s-control-2"
      "--data-dir=/var/lib/rancher/k3s"
      "--node-ip=10.0.0.3"
      "--tls-san=10.0.0.3"
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

    charts = {
      cilium = pkgs.fetchurl {
        url = "https://helm.cilium.io/cilium-1.17.0.tgz"; # Fetch Helm chart
        sha256 = "sha256-cqggvwG7PgLAGFaJKgUI2pLfyUF0+HBce8tduxXiKP4="; # lib.fakeSha256; # Replace with actual sha256 from Helm repo
      };
    };
  };
}
