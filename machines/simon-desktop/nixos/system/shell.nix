{ pkgs, ... }:
{
  users.users.simon.shell = pkgs.fish;

  programs.fish = {
    enable = true;
    useBabelfish = true;
  };
}
