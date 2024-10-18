{
  inputs,
  ...
}:
{
  nixpkgs.overlays = [
    # master default
    (final: _prev: {
      git = import inputs.nixpkgs-git {
        inherit (final) system;
      };
    })

    # master w/ unfree
    (final: _prev: {
      git-unfree = import inputs.nixpkgs-git {
        inherit (final) system;
        config.allowUnfree = true;
      };
    })
  ];
}
