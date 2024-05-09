{pkgs, ...}: {
  imports = [
    ../../desktop/x11/i3
    ../../desktop/wayland/hyprland
    ../../browser/firefox.nix
    ../../shell/starship.nix
    ../../shell/zsh.nix
    ../../games.nix
    ../../mangohud.nix
    ../../git.nix
    ../../gtk.nix
    ../../terminal/emulators/kitty.nix
    ../../terminal/yazi/yazi.nix
    ../../terminal/cli.nix
    ../../terminal/bat.nix
    ../../terminal/btop.nix
    ../../editors/neovim.nix
    ../../editors/vscodium.nix
    ../../packages.nix
    ../../xdg.nix
    ../../zathura.nix
    ../../sops.nix
    ../../utils.nix
    #../../stylix.nix
    ../../mpv.nix
    ../../udiskie.nix
    ../../editors/zed.nix
    ../../polkit-agent.nix
  ];

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
