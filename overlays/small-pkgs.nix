{ inputs, ... }:
final: _prev: {
  small = import inputs.nixpkgs-small {
    inherit (final.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
}
