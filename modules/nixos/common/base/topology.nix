{ inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = [ inputs.nix-topology.nixosModules.default ];

    topology.self.interfaces = {
      wt0 = {
        virtual = true;
        type = "wireguard";
        network = "netbird";
      };
      wireguard = {
        virtual = true;
        type = "wireguard";
        network = "wireguard";
      };
      ygg0 = {
        virtual = true;
        network = "yggdrasil";
      };
    };
  };
}
