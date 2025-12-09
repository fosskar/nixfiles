{ lib, ... }:
{
  # servers don't need man pages
  documentation.man = {
    enable = lib.mkDefault false;
    generateCaches = lib.mkDefault false;
  };
}
