{
  # machine ip facts, single source of truth. pure metadata; reachable
  # everywhere via self/flake-self (modules) and config.flake.hosts
  # (flake-parts/clan). consumers: clan inventory (internet, wireguard),
  # machines/*/networking.nix, feature-module trusted proxies, topology.
  flake.hosts = {
    gateway.wan = "138.201.155.21";
    nixbox.lan = "192.168.20.200";
    nixworker.lan = "192.168.20.210";
    simon-desktop.lan = "192.168.10.100";
    lpt-titan.lan = "192.168.10.150";
  };
}
