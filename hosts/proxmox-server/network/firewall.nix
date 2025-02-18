{ lib, ... }:
{
  networking = {
    firewall = {
      enable = true;
      allowPing = true;
      checkReversePath = "loose";
      logRefusedConnections = lib.mkDefault false;
      trustedInterfaces = [
        "cilium_host"
        "cilium_net"
        "cilium_vxlan"
        "cilium_geneve"
        "lxc*"
        "tailscale0"
      ];
      allowedTCPPorts = [
        22
        6443 # yes kapi
        2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
        2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
        4240 # health check
        4244 # hubble server
        4245 # hubble relay
        9962 # agent prometheus metrics
        9963 # operator prometheus metrics
        9964 # envoy prometheus metrics
        10250 # metrics
      ];
      allowedUDPPorts = [
        8472 # for vxlan
        6081 # for Geneve
        51820 # wireguard
      ];
    };
  };
}
