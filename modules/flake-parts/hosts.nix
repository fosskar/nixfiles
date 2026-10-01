{
  # machine ip facts, single source of truth. pure metadata; reachable
  # everywhere via self/flake-self (modules) and config.flake.hosts
  # (flake-parts/clan). consumers: clan inventory (internet, wireguard),
  # machines/*/networking.nix, feature-module trusted proxies.
  flake.hosts = {
    gateway.wan = "138.201.155.21";
    gateway.wan6 = "2a01:4f8:c17:b207::1";
    nixbox.lan = "192.168.20.200";
    nixworker.lan = "192.168.20.210";
    desktop.lan = "192.168.10.100";
    lpt-titan.lan = "192.168.10.150";
  };

  # the openwrt router's address on each network; gateway and dns (adguard)
  # for the machines there. outside flake.hosts, which the clan inventory
  # treats as a list of machines
  flake.router = {
    lan = "192.168.10.1";
    srv = "192.168.20.1";
  };
}
