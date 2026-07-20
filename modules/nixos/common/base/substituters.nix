{
  flake.modules.nixos.base = {
    nix.settings = {
      # cache.nixos.org comes from nixpkgs config/nix.nix (mkAfter); its
      # narinfo priority 40 already beats cachix (41), so no local entry
      substituters = [
        "https://nix-community.cachix.org"
        "https://nix-gaming.cachix.org"
        "https://numtide.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      ];
    };
  };
}
