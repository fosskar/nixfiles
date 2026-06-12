{
  flake.modules.nixos.base =
    { self, ... }:
    {
      nixpkgs = {
        overlays = [ self.overlays.default ];

        config = {
          allowBroken = false;
          allowUnsupportedSystem = true;
          allowDeprecatedx86_64Darwin = true;
          allowUnfree = true;
          permittedInsecurePackages = [ ];
          allowAliases = true;
          # true causes full-closure mass rebuild
          enableParallelBuildingByDefault = false;
          # see pkgs/stdenv/generic/check-meta.nix for valid values
          showDerivationWarnings = [ ];
        };
      };
    };
}
