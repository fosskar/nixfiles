{
  flake.modules.nixos.base =
    { self, inputs, ... }:
    {
      nixpkgs = {
        overlays = [ self.overlays.default ] ++ import (self + "/overlays") { inherit inputs; };

        config = {
          allowUnfree = true;
          # the unencrypted, unauthenticated transport only exposes private
          # repos; nodes here seed public repos only. drop once the iroh-based
          # release lands:
          # https://radicle.dev/2026/09/23/disclosure-of-vulnerability-in-network-protocol
          permittedInsecurePackages = [ "radicle-node-1.10.3" ];
        };
      };
    };
}
