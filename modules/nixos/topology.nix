{ inputs, ... }:
{
  imports = [ inputs.nix-topology.flakeModule ];

  # nix-topology collects interfaces/services from every host that imports its
  # nixos module. wire it into base so all machines participate.
  # build per-system diagrams: `nix build .#topology.x86_64-linux.config.output`
  flake.modules.nixos.base.imports = [ inputs.nix-topology.nixosModules.default ];

  # global topology: the openwrt router, the internet, and the shared networks.
  # per-host interface details live in each machine's networking.nix via topology.self.
  perSystem.topology.modules = [
    (
      { config, ... }:
      let
        inherit (config.lib.topology) mkInternet mkRouter mkConnection;
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
          internet.name = "Internet";
        };

        nodes.internet = mkInternet {
          connections = [
            (mkConnection "router" "wan")
            (mkConnection "gateway" "wan")
          ];
        };

        nodes.router = mkRouter "OpenWrt" {
          info = "openwrt (192.168.10.1 / 192.168.20.1)";
          # separate groups so the two subnets don't share a network
          interfaceGroups = [
            [ "lan" ]
            [ "srv" ]
            [ "wan" ]
          ];
          connections.lan = [
            (mkConnection "simon-desktop" "lan")
            (mkConnection "lpt-titan" "lan")
          ];
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
        };
      }
    )
  ];
}
