{ inputs, ... }:
{
  flake.modules.nixos.base.imports = [
    inputs.nix-topology.nixosModules.default
    (
      { config, lib, ... }:
      let
        inherit (config.lib.topology) mkConnection;
        toGateway = lib.mkIf (config.networking.hostName != "gateway");
      in
      {
        topology.self.interfaces = {
          wt0 = {
            virtual = true;
            type = "wireguard";
            network = "netbird";
            renderer.hidePhysicalConnections = true;
            physicalConnections = toGateway [ (mkConnection "gateway" "wt0") ];
          };
          wireguard = {
            virtual = true;
            type = "wireguard";
            network = "wireguard";
            addresses = lib.mkForce [ "fd28:387a:4e:a500::/64" ];
            renderer.hidePhysicalConnections = true;
            physicalConnections = toGateway [ (mkConnection "gateway" "wireguard") ];
          };
          ygg = {
            virtual = true;
            network = "yggdrasil";
            renderer.hidePhysicalConnections = true;
          };
        };
      }
    )
  ];
}
