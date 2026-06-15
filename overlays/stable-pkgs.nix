{ inputs, ... }:
final: _prev: {
  stable = import inputs.nixpkgs {
    inherit (final.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
}
