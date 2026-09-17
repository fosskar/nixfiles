{ ... }:
_final: prev: {
  # sops-nix still calls buildGo125Module, which nixpkgs removed as
  # end-of-life; drop this once Mic92/sops-nix moves to a current builder
  buildGo125Module = prev.buildGoModule;
}
