{
  config,
  pkgs,
  lib,
  ...
}: {
  services.k3s.enable = true;
  services.k3s.role = "server";
  services.k3s.extraFlags = toString [
    # "--kubelet-arg=v=4" # Optionally add additional args to k3s
  ];
  environment.systemPackages = with pkgs; [
    k3s
    kubectl
    kubernetes-helm
    k9s
  ];
}
