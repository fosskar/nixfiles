{ pkgs, ... }:
{
  chaotic.scx = {
    enable = true;
    package = pkgs.scx.rustland;
    scheduler = "scx_rustland"; # rustland is default
  };
}
