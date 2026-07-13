{ inputs, ... }:
final: _prev: {
  stable = import inputs.nixpkgs-stable {
    inherit (final.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
}
