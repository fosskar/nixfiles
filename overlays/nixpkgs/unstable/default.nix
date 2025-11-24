{
  inputs,
  ...
}:
{
  nixpkgs.overlays = [
    # unstable default
    (final: _prev: {
      unstable = import inputs.nixpkgs {
        inherit (final.stdenv.hostPlatform) system;
      };
    })

    # unstable w/ default
    (final: _prev: {
      unstable-unfree = import inputs.nixpkgs {
        inherit (final.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
    })
  ];
}
