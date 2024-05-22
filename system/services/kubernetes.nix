{pkgs, ...}:
# see https://nixos.org/nixos/manual/index.html#sec-kubernetes
let
  kubeMasterIP = "192.168.178.91";
  kubeMasterHostname = "localhost";
  kubeMasterAPIServerPort = 6443;
in {
  networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";

  environment.systemPackages = with pkgs; [
    kompose
    kubectl
    kubernetes
  ];

  services.kubernetes = {
    roles = ["master" "node"];
    masterAddress = kubeMasterHostname;
    apiserverAddress = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
    easyCerts = true;
    apiserver = {
      securePort = kubeMasterAPIServerPort;
      advertiseAddress = kubeMasterIP;
    };

    #apiserver.enable = true;

    addons = {
      dns.enable = true;
      flannel.enable = true;
    };

    kubelet.extraOpts = "--fail-swap-on=false";
  };
}
