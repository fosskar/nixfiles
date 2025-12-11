{ inputs }:
final: _prev: {
  master = import inputs.nixpkgs-git {
    inherit (final.stdenv.hostPlatform) system;
  };
  master-unfree = import inputs.nixpkgs-git {
    inherit (final.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
}
