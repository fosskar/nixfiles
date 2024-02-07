{pkgs, ...}: {
  imports = [
    ../../modules/browser.nix
    ../../modules/cli.nix
    ../../modules/git.nix
    ../../modules/kitty.nix
    ../../modules/neovim.nix
    ../../modules/starship.nix
    ../../modules/vscodium.nix
    ../../modules/zathura.nix
    ../../modules/zsh.nix
  ];

  nixpkgs = {
    overlays = [];
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = ["nix-command" "flakes"];
    };
  };

  home = {
    username = "simon";
    homeDirectory = "/home/simon";
    sessionVariables = {
      SHELL = "${pkgs.zsh}/bin/zsh";
    };
  };

  ## reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  home.stateVersion = "23.11";
}
