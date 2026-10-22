{ config, lib, ... }:
let
  inherit (config.flake) hosts router;
  subnet = ip: lib.concatStringsSep "." (lib.init (lib.splitString "." ip));
  # machines that never leave the home lan; lpt-titan roams
  stationary = [
    "nixbox"
    "nixworker"
    "desktop"
    "ha-green"
  ];
in
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
    ha-green.lan = "192.168.10.50";
  };

  # the openwrt router's address on each network; gateway and dns (adguard)
  # for the machines there. outside flake.hosts, which the clan inventory
  # treats as a list of machines
  flake.router = {
    lan = "192.168.10.1";
    srv = "192.168.20.1";
  };

  # lan ip that `from` dials to reach `to` without an overlay, or null when
  # `from` must use the clan name <to>.s. both must be stationary and `to`
  # must sit in srv: the router forwards lan -> srv but rejects srv -> lan
  flake.lanAddress =
    from: to:
    if
      lib.elem from stationary && lib.elem to stationary && subnet hosts.${to}.lan == subnet router.srv
    then
      hosts.${to}.lan
    else
      null;
}
