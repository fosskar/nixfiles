{ inputs, ... }:
{
  imports = [ inputs.nix-topology.flakeModule ];

  # global topology: the openwrt router, the dumb ap, the internet, and the
  # shared networks. per-host interface details live in each machine's
  # networking.nix via topology.self.
  # build per-system diagrams: `nix build .#topology.x86_64-linux.config.output`
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
          home = {
            name = "Home LAN";
            cidrv4 = "192.168.10.0/24";
          };
          server = {
            name = "Server LAN";
            cidrv4 = "192.168.20.0/24";
          };
          iot = {
            name = "IoT Network";
            cidrv4 = "192.168.50.0/24";
          };
          internet.name = "Internet";
        };

        nodes.internet = mkInternet {
          connections = [
            (mkConnection "router" "wan")
            (mkConnection "gateway" "wan")
          ];
        };

        nodes.router = mkRouter "OpenWrt Router" {
          info = "openwrt (br-lan .10.1 / br-servers .20.1 / br-iot .50.1)";
          # separate groups so the subnets don't share a network
          interfaceGroups = [
            [ "lan" ]
            [ "srv" ]
            [ "iot" ]
            [ "wan" ]
          ];
          # br-lan: wired desktop + the dumb AP uplink
          connections.lan = [
            (mkConnection "simon-desktop" "lan")
            (mkConnection "ap" "uplink")
          ];
          # br-servers (lan1): the two servers
          connections.srv = [
            (mkConnection "nixbox" "bond0")
            (mkConnection "nixworker" "bond0")
          ];
          interfaces.lan = {
            addresses = [ "192.168.10.1" ];
            network = "home";
          };
          interfaces.srv = {
            addresses = [ "192.168.20.1" ];
            network = "server";
          };
          interfaces.iot = {
            addresses = [ "192.168.50.1" ];
            network = "iot";
          };
        };

        # zyxel nwa50ax in dumb-ap mode: bridges wifi onto br-lan.
        # wifi clients (e.g. the laptop) reach the net through here.
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
            network = "home";
          };
        };
      }
    )
  ];
}
