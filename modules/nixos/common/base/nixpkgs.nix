{
  flake.modules.nixos.base =
    { self, inputs, ... }:
    {
      nixpkgs = {
        overlays = [
          self.overlays.default
          inputs.llm-agents.overlays.default
        ]
        ++ import (self + "/overlays") { inherit inputs; };

        config.allowUnfree = true;
      };
    };
}
