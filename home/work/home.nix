{ pkgs, ... }:
{
  imports = [
    ./browser/firefox
    ./desktop/x11/i3
    ./editors/vscodium.nix
    ./editors/nixvim.nix
    ./editors/zed.nix
    ./nix
    ./programs/autorandr.nix
    ./programs/gpg.nix
    ./programs/gtk.nix
    ./programs/home-manager.nix
    ./programs/jq.nix
    ./programs/k9s.nix
    ./programs/packages.nix
    ./programs/qt.nix
    ./programs/ssh.nix
    ./programs/xdg.nix
    ./programs/zathura.nix
    ./secrets/sops.nix
    ./services/autorandr.nix
    ./services/flameshot.nix
    ./services/fonts.nix
    ./services/polkit-agent.nix
    ./services/remmina.nix
    ./services/udiskie.nix
    ./terminal
  ];

  home = {
    username = "simon";
    homeDirectory = "/home/simon";
    sessionVariables = {
      SHELL = "${pkgs.zsh}/bin/zsh";
    };
    stateVersion = "23.11";
  };
  targets.genericLinux.enable = true;
}
