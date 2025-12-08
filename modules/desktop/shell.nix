{ lib, ... }:
{
  # desktop uses home-manager for zsh - disable system completion to avoid duplication
  environment.pathsToLink = [ "/share/zsh" ];

  programs = {
    less.enable = lib.mkDefault true;

    zsh = {
      enable = lib.mkDefault true;
      enableLsColors = lib.mkDefault true;
      # disabled - home-manager handles completion to avoid duplicate compinit calls
      # see: https://github.com/nix-community/home-manager/issues/3965
      enableGlobalCompInit = lib.mkDefault false;
      enableCompletion = lib.mkDefault false;
      enableBashCompletion = lib.mkDefault false;
      autosuggestions.enable = lib.mkDefault false;
      syntaxHighlighting.enable = lib.mkDefault false;
    };
  };
}
