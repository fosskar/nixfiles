{ lib, ... }:
{
  # desktop uses home-manager for zsh - disable system completion to avoid duplication
  # see: https://github.com/nix-community/home-manager/issues/3965
  programs.zsh = {
    enableGlobalCompInit = lib.mkDefault false;
    enableCompletion = lib.mkDefault false;
    enableBashCompletion = lib.mkDefault false;
    autosuggestions.enable = lib.mkDefault false;
    syntaxHighlighting.enable = lib.mkDefault false;
  };
}
