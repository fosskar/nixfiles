{pkgs, ...}: {
  imports = [
    #./argocd.nix
  ];

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      # "--kubelet-arg=v=4" # Optionally add additional args to k3s
      "--cluster-domain=kube"
    ];
  };
  environment.systemPackages = with pkgs; [
    k3s
    kubernetes-helm
    k9s
  ];
}
