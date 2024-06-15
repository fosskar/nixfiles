{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.matugen.nixosModules.default
    ../../browser/firefox
    ../../desktop/wayland/hyprland
    ../../desktop/x11/i3
    ../../editors/nixvim.nix
    ../../editors/vscodium.nix
    ../../editors/zed.nix
    ../../programs/gtk.nix
    ../../programs/mangohud.nix
    ../../programs/mpv.nix
    ../../programs/packages.nix
    ../../programs/qt.nix
    ../../programs/ssh.nix
    ../../programs/utils.nix
    ../../programs/xdg.nix
    ../../programs/zathura.nix
    ../../services/audio.nix
    ../../services/system/polkit-agent.nix
    ../../services/system/udiskie.nix
    ../../terminal
    ./secrets/sops.nix
  ];

  programs.home-manager.enable = true;

  home = {
    username = "simon";
    homeDirectory = "/home/simon";
    sessionVariables = {
      SHELL = "${pkgs.zsh}/bin/zsh";
    };
    stateVersion = "23.11";
  };
  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };
}
