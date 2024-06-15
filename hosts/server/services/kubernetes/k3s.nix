{pkgs, ...}: {
  imports = [
    ../../../../modules/nixos/kubernetes/k3s.nix
  ];

  services.k3sManaged = {
    enable = true;
    nodeName = "kube-nixos";
    clusterDomain = "kube-nixos.space";
    clusterCIDR = "10.42.0.0/16";
    serviceCIDR = "10.43.0.0/16";
    clusterDNS = "10.43.0.10";
    zfs = true;
    disableTraefik = false;
    disableFlannel = false;
    disableKubeProxy = false;
    disableMetricsServer = false;
    package = pkgs.k3s;
    tlsSAN = "nixos.space";
    #apiServerArgs = ["--arg1=value1" "--arg2=value2"];
    deviceOwnershipFromSecurityContext = false;
  };
}
