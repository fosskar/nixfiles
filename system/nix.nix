{
  pkgs,
  inputs,
  ...
}: {
  documentation.nixos.enable = false;

  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
      # hyprland cachix
      substituters = [
        "https://hyprland.cachix.org"
        "https://nix-gaming.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      ];
    };
    gc = {
      automatic = false; # because i am using nh.clean
      dates = "weekly";
      options = "--delete-older-than 1w";
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
}
