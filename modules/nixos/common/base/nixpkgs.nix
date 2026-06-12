{
  flake.modules.nixos.base =
    { self, ... }:
    {
      nixpkgs = {
        overlays = [ self.overlays.default ];

        config.allowUnfree = true;
      };
    };
}
