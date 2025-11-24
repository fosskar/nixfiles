{
  inputs,
  ...
}:
{
  nixpkgs.overlays = [
    # stable default
    (final: _prev: {
      stable = import inputs.nixpkgs-stable {
        inherit (final.stdenv.hostPlatform) system;
      };
    })

    # stable w/ unfree
    (final: _prev: {
      stable-unfree = import inputs.nixpkgs-stable {
        inherit (final.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
    })
  ];
}
