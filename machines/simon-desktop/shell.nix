{ pkgs, ... }:
{
  users.defaultUserShell = pkgs.fish; # users get fish
  users.users.root.shell = pkgs.zsh; # root gets zsh

  programs = {
    fish = {
      enable = true;
      useBabelfish = true;
    };
    zsh.enable = true;
  };
}
