{pkgs, ...}: {
  imports = [
    ../../terminal/programs/bat.nix
    ../../terminal/programs/btop.nix
    ../../terminal/programs/yazi
    ../../terminal/shell/bash.nix
    ../../terminal/shell/starship.nix
    ../../terminal/emulators/kitty.nix
    ../../programs/gtk.nix
    #../../programs/qt.nix
    ../../programs/utils.nix
    ../../programs/xdg.nix
    ../../programs/zathura.nix
    ../../editors/zed.nix
    ../../editors/nixvim.nix
    #../../desktop/x11/i3
    ../../services/system/polkit-agent.nix
  ];

  programs.home-manager.enable = true;

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };

  home = {
    username = "simon";
    homeDirectory = "/home/simon";
    sessionVariables = {
      SHELL = "${pkgs.zsh}/bin/zsh";
    };
    stateVersion = "23.11";
    packages = with pkgs; [
      slack
      virt-manager
      libreoffice
      remmina
      obsidian
      yq
    ];
    sessionVariables.BROWSER = "firefox";
  };

  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };
}
