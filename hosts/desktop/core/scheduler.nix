{ pkgs, ... }:
{
  chaotic.scx = {
    enable = true;
    package = pkgs.scx_git.rustland;
    scheduler = "scx_rustland"; # rustland is default
  };
}
