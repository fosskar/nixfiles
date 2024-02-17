{pkgs, ...}: let
  # Define the base path to the modules
  basePath = ../../modules/home-manager;

  # List of modules to import, relative to the base path
  modules = [
    "desktop/x11/i3"
    # "desktop/wayland/ags"
    "desktop/wayland/hyprland"
    "desktop/wayland/waybar"
    "desktop/wayland/wofi.nix"
    "desktop/wayland/wlogout"
    "desktop/wayland/dunst.nix"
    "browser/firefox.nix"
    "shell/cli.nix"
    "fonts.nix"
    "games.nix"
    "git.nix"
    "gtk.nix"
    "terminals/kitty.nix"
    "editors/neovim.nix"
    "packages.nix"
    "shell/starship.nix"
    "editors/vscodium.nix"
    "xdg.nix"
    "zathura.nix"
    "shell/zsh.nix"
    "sops.nix"
    "shell/bat.nix"
    "direnv.nix"
    "yazi/yazi.nix"
    "stylix.nix"
  ];
in {
  imports = builtins.map (module: "${basePath}/${module}") modules;

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
