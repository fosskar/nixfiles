{
  inputs,
  ...
}:
{
  nixpkgs.overlays = [
    # master default
    (final: _prev: {
      git = import inputs.nixpkgs-git {
        inherit (final.stdenv.hostPlatform) system;
      };
    })

    # master w/ unfree
    (final: _prev: {
      git-unfree = import inputs.nixpkgs-git {
        inherit (final.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
    })
  ];
}
