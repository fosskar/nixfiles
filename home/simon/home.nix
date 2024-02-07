{pkgs, ...}: {
  imports = [
    ../../modules/desktop/x11/i3
    #../../modules/desktop/wayland/ags
    ../../modules/desktop/wayland/hyprland
    ../../modules/desktop/wayland/waybar
    ../../modules/desktop/wayland/wofi.nix
    ../../modules/desktop/wayland/wlogout
    ../../modules/browser/firefox.nix
    ../../modules/shell/cli.nix
    ../../modules/fonts.nix
    ../../modules/games.nix
    ../../modules/git.nix
    ../../modules/gtk.nix
    ../../modules/terminals/kitty.nix
    ../../modules/editors/neovim.nix
    ../../modules/packages.nix
    ../../modules/shell/starship.nix
    ../../modules/editors/vscodium.nix
    ../../modules/xdg.nix
    ../../modules/zathura.nix
    ../../modules/shell/zsh.nix
    ../../modules/sops.nix
    #../../modules/stylix.nix
  ];

  nixpkgs = {
    overlays = [];
    config = {
      allowUnfree = true;
    };
  };

  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = ["nix-command" "flakes"];
    };
  };

  programs.home-manager.enable = true;

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
