{ inputs, ... }:
{
  imports = [ inputs.nix-topology.flakeModule ];

  perSystem.topology.modules = [
    (
      { config, ... }:
      let
        inherit (config.lib.topology)
          mkInternet
          mkRouter
          mkSwitch
          mkConnection
          ;
      in
      {
        networks = {
          lan = {
            name = "Home LAN";
            cidrv4 = "192.168.10.0/24";
          };
          srv = {
            name = "Servers";
            cidrv4 = "192.168.20.0/24";
          };
          iot = {
            name = "IoT Network";
            cidrv4 = "192.168.50.0/24";
          };
          wan.name = "Internet";
        };

        nodes.internet = mkInternet {
          connections = [
            (mkConnection "router" "wan")
            (mkConnection "gateway" "wan")
          ];
        };

        nodes.router = mkRouter "OpenWrt Router" {
          info = "openwrt (br-lan .10.1 / br-servers .20.1 / br-iot .50.1)";
          interfaceGroups = [
            [ "lan" ]
            [ "srv" ]
            [ "iot" ]
            [ "wan" ]
          ];
          connections.lan = [
            (mkConnection "simon-desktop" "lan")
            (mkConnection "ap" "uplink")
          ];
          connections.srv = [
            (mkConnection "nixbox" "bond0")
            (mkConnection "nixworker" "bond0")
          ];
          interfaces.lan = {
            addresses = [ "192.168.10.1" ];
            network = "lan";
          };
          interfaces.srv = {
            addresses = [ "192.168.20.1" ];
            network = "srv";
          };
          interfaces.iot = {
            addresses = [ "192.168.50.1" ];
            network = "iot";
          };
        };

        nodes.ap = mkSwitch "OpenWrt AP" {
          info = "zyxel nwa50ax (dumb ap, 192.168.10.2)";
          interfaceGroups = [
            [
              "uplink"
              "wifi"
            ]
          ];
          connections.wifi = mkConnection "lpt-titan" "wlan";
          interfaces.uplink = {
            addresses = [ "192.168.10.2" ];
            network = "lan";
          };
        };
      }
    )
  ];
}
