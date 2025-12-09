{ lib, ... }:
{
  # servers don't need man pages
  documentation.man.enable = lib.mkDefault false;
}
