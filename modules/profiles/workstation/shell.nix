{ pkgs, ... }:
{
  # default shells for workstations
  users.defaultUserShell = pkgs.fish;
  users.users.root.shell = pkgs.zsh;

  programs.fish = {
    enable = true;
    useBabelfish = true;
  };

  # desktop uses home-manager for zsh - disable system completion to avoid duplication
  # see: https://github.com/nix-community/home-manager/issues/3965
  programs.zsh = {
    enableGlobalCompInit = false;
    enableCompletion = false;
    enableBashCompletion = false;
    autosuggestions.enable = false;
    syntaxHighlighting.enable = false;
  };
}
